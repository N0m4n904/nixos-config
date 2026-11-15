# Shares directories of this host with other machines over voidport.
#
# A namespace starts out sharing nothing and a rule attaches one directory to it,
# so a guest can open exactly what is declared here and nothing else of this
# filesystem. A rule can also be changed through voidport-ctl while mounts are in
# place, which is why the declared document is installed into the state directory
# instead of being used from the store. See `declared` below.
#
# A guest is never authenticated: the only auth mode in voidport is "none", and
# the traffic is neither encrypted nor signed. What can open a listener is
# therefore a consequence of which interfaces the port is opened on, which is
# the purpose of `firewallInterfaces`.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.voidport.serve;

  stateFile = import ./state-file.nix { inherit lib; };

  voidport = inputs.voidport.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # voidportd owns its state file: every change made through voidport-ctl is
  # written back into it. A path in the store is read-only and would cost that, so
  # the declared document is installed over the copy in use at every start. Both
  # properties then apply at once: a rule can be changed while mounts are in
  # place, and a restart brings back what the configuration declares.
  declared = (pkgs.formats.toml { }).generate "voidport-state.toml" (
    stateFile.renderDocument { inherit (cfg) tcpListeners namespaces; }
  );

  servedState = "/var/lib/voidport/state.toml";

  directoriesWhere =
    predicate:
    lib.concatMap (
      namespace: lib.attrNames (lib.filterAttrs (_: shared: predicate shared) namespace.directories)
    ) (lib.attrValues cfg.namespaces);

  sharedDirectories = directoriesWhere (_: true);
  writableDirectories = directoriesWhere (shared: stateFile.grantsWriting shared.mode);

  portsLeftClosed = lib.subtractLists config.networking.firewall.allowedTCPPorts (
    map (listener: listener.port) cfg.tcpListeners
  );
in
{
  options.voidport.serve = {
    user = lib.mkOption {
      type = lib.types.str;
      example = "builder";
      description = ''
        The account used to run the server, whose permissions limit what it can
        read of the directories shared here. The control socket is created with
        mode 0600 for the same account, so this is also the account that can
        change rules through voidport-ctl.

        Deliberately without a default. A directory under a home directory needs
        the account of that home. For a directory outside one, an account with
        access to that directory alone is enough. A default chosen here would
        give the server more of this filesystem than the share needs.
      '';
    };

    tcpListeners = lib.mkOption {
      type = lib.types.listOf stateFile.tcpListenerType;
      default = [ ];
      example = [ { port = 9000; } ];
      description = ''
        The TCP endpoints used by guests to connect. At least one is required,
        because voidport has no default bind, and a server without a listener
        cannot be mounted.
      '';
    };

    firewallInterfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "tailscale0" ];
      description = ''
        Interfaces on which the ports of the listeners are opened. This is the
        whole of the access control in front of a server that authenticates
        nobody, so list the interfaces whose machines are trusted with the
        directories shared here.

        Left empty, this module changes nothing about the firewall, and the ports
        are then open only where the rest of the configuration opens them.
      '';
    };

    namespaces = lib.mkOption {
      type = lib.types.attrsOf stateFile.namespaceType;
      default = { };
      example = {
        artifacts.directories."/srv/artifacts" = { };
      };
      description = ''
        What this host shares, keyed by the namespace name used by guests to
        mount it. A namespace groups the directories that belong together for
        whoever mounts them. Declaring one starts the server.
      '';
    };
  };

  config = lib.mkIf (cfg.namespaces != { }) {
    assertions = [
      {
        assertion = cfg.tcpListeners != [ ];
        message = ''
          voidport.serve declares namespaces while its list of TCP listeners is
          empty, so nothing can mount them. Set voidport.serve.tcpListeners.
        '';
      }
      {
        assertion = lib.all (
          name: builtins.match "[^/[:cntrl:]]+" name != null && builtins.stringLength name <= 255
        ) (lib.attrNames cfg.namespaces);
        message = ''
          A voidport namespace name is at most 255 bytes long and contains
          neither "/" nor a control character. Rename the offending entry of
          voidport.serve.namespaces.
        '';
      }
      {
        assertion = lib.all (namespace: namespace.directories != { }) (lib.attrValues cfg.namespaces);
        message = ''
          Every namespace of voidport.serve.namespaces needs at least one entry
          under its directories. A namespace without one shares nothing.
        '';
      }
      {
        assertion = lib.all (
          directory: lib.hasPrefix "/" directory && !lib.hasSuffix "/" directory && directory != "/"
        ) sharedDirectories;
        message = ''
          A directory shared by voidport.serve.namespaces is given by the
          absolute path it has on this host, without a trailing slash. The
          filesystem root cannot be shared, because voidport treats "/" as an
          invalid rule path.
        '';
      }
      {
        assertion =
          !config.networking.firewall.enable || cfg.firewallInterfaces != [ ] || portsLeftClosed == [ ];
        message = ''
          voidport.serve listens on ${lib.concatMapStringsSep ", " toString portsLeftClosed} while the
          firewall closes those ports, so nothing can mount what is shared. List
          the interfaces to open them on in voidport.serve.firewallInterfaces, or
          open the ports through networking.firewall directly.
        '';
      }
    ];

    environment.systemPackages = [ voidport ];

    networking.firewall.interfaces = lib.genAttrs cfg.firewallInterfaces (_: {
      allowedTCPPorts = map (listener: listener.port) cfg.tcpListeners;
    });

    systemd.services.voidportd = {
      description = "Serve declared directories over voidport";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      # The target of a rule has to exist when the document is loaded, and a
      # shared directory is as likely as not a filesystem of its own. systemd
      # works out which mount units these paths belong to.
      unitConfig.RequiresMountsFor = sharedDirectories;

      serviceConfig = {
        Type = "notify";
        User = cfg.user;
        Restart = "on-failure";

        # Contains the control socket, at the path used by voidportd when the
        # document does not set one.
        RuntimeDirectory = "voidport";
        StateDirectory = "voidport";

        ExecStartPre = "${lib.getExe' pkgs.coreutils "install"} -m 0600 ${declared} ${servedState}";
        ExecStart = "${lib.getExe' voidport "voidportd"} --state ${servedState}";

        # The server reads the filesystem and writes only where a rule allows it,
        # so everything outside those directories can be read-only to it. Where
        # no rule allows writing, only its own state directory is writable.
        ProtectSystem = "strict";
        ReadWritePaths = lib.mkIf (writableDirectories != [ ]) writableDirectories;
        PrivateDevices = true;
        PrivateTmp = true;
        NoNewPrivileges = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        RestrictAddressFamilies = [
          "AF_UNIX"
          "AF_INET"
          "AF_INET6"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        SystemCallArchitectures = "native";

        # RestrictSUIDSGID cannot be used with this server. systemd enforces it by
        # inspecting the mode argument of the open and chmod family, and openat2
        # passes that argument inside a struct in memory, which a seccomp filter
        # cannot read, so systemd blocks openat2 outright. openat2 is the only
        # call used by the server to open anything inside a share, which then
        # fails with ENOSYS. What this gives up is protection against setuid bits
        # being set on files of this host through a writable share, which voidport
        # itself covers through privileged_bits on a namespace.
        #
        # SystemCallFilter is left out for a related reason. The calls needed by
        # this server fall outside the curated sets of systemd in both directions:
        # openat2 appears in none of them, and the fchownat used to apply the
        # ownership sent by a guest to a file it creates belongs to @privileged. A
        # filter that misses one of those does not cost the operation. The thread
        # takes SIGSYS and the whole server exits, so every guest loses its mount
        # over a single call left out of the list. The account used to run the
        # service and the read-only filesystem around its shares bound it instead.
      };
    };
  };
}
