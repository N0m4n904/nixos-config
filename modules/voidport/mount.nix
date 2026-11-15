# Mounts directories shared by other machines over voidport.
#
# Through the FUSE client of voidport instead of its kernel module. That module
# is written in Rust against one kernel version of the nixpkgs revision locked
# upstream, and mount(8), fstab and systemd automounts all use voidport only
# through it, so none of those are available here. The client is also the half
# that survives a machine which comes and goes: once the mount is made, a server
# that disappears stalls requests briefly and then fails them, while the client
# reconnects on its own and resumes as soon as the server replies again.
#
# The first handshake is the exception made deliberately upstream. A mount that
# cannot be established is an error instead of a mount that starts out degraded
# without saying so, so the client exits and the service retries. That retry is
# also how a mount comes up on a machine booted far from its server.
{
  config,
  inputs,
  lib,
  pkgs,
  utils,
  ...
}:

let
  cfg = config.voidport.mounts;

  voidport = inputs.voidport.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # A shared directory is opened at the absolute path it has on the serving host,
  # which the URL repeats as the subpath after the namespace.
  mountUrl =
    {
      server,
      port,
      namespace,
      directory,
      ...
    }:
    "voidport://${server}:${toString port}/@${namespace}${directory}";

  mountCommand =
    mountpoint: mount:
    lib.escapeShellArgs (
      [
        (lib.getExe' voidport "voidport")
        "mount"
        (mountUrl mount)
        mountpoint
      ]
      ++ lib.optional mount.allowOther "--allow-other"
      ++ lib.optional mount.readOnly "--read-only"
    );

  mountType = lib.types.submodule {
    options = {
      server = lib.mkOption {
        type = lib.types.str;
        example = "build-host";
        description = ''
          The machine that shares the directory. Nothing about the connection is
          encrypted or authenticated, so this needs a name that resolves over a
          network whose machines are trusted with what is mounted.
        '';
      };

      port = lib.mkOption {
        type = lib.types.port;
        example = 9000;
        description = "The port the serving host listens on.";
      };

      namespace = lib.mkOption {
        type = lib.types.str;
        example = "artifacts";
        description = "The namespace on that host which shares the directory.";
      };

      directory = lib.mkOption {
        type = lib.types.str;
        example = "/srv/artifacts";
        description = ''
          The directory to mount, given by the absolute path it has on the
          serving host. That is the path it is shared at. Mounting it instead of
          the namespace root puts its contents directly at the mountpoint.
        '';
      };

      readOnly = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Have the kernel of this machine reject writes as well, instead of
          leaving them to the rule on the serving host. Useful wherever the share
          is read-only anyway: a write then fails here, with the error of a
          read-only filesystem, instead of after a round trip.
        '';
      };

      allowOther = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Let accounts other than the one that mounted use the mount. On by
          default because a system service makes the mount, so without it only
          root could use what was mounted. Permissions from the serving host are
          still enforced against whoever reads, so this affects who may use the
          mount and not what they may read through it.
        '';
      };
    };
  };
in
{
  options.voidport.mounts = lib.mkOption {
    type = lib.types.attrsOf mountType;
    default = { };
    example = {
      "/mnt/artifacts" = {
        server = "build-host";
        port = 9000;
        namespace = "artifacts";
        directory = "/srv/artifacts";
        readOnly = true;
      };
    };
    description = ''
      Directories to mount from other machines, keyed by where each one is
      mounted on this host.
    '';
  };

  config = lib.mkIf (cfg != { }) {
    assertions = [
      {
        assertion = lib.all (mountpoint: lib.hasPrefix "/" mountpoint) (lib.attrNames cfg);
        message = "A mountpoint of voidport.mounts is an absolute path.";
      }
      {
        assertion = lib.all (mount: lib.hasPrefix "/" mount.directory) (lib.attrValues cfg);
        message = ''
          The directory of a voidport.mounts entry is the absolute path it has on
          the serving host, which is the path it is shared at.
        '';
      }
    ];

    # FUSE is built as a module in this kernel, and it can still be unloaded when
    # a mount is attempted at boot. Without it there is no /dev/fuse for the
    # client to open.
    boot.kernelModules = [ "fuse" ];

    environment.systemPackages = [ voidport ];

    systemd.services = lib.mapAttrs' (
      mountpoint: mount:
      lib.nameValuePair "voidport-mount-${utils.escapeSystemdPath mountpoint}" {
        description = "Mount ${mount.directory} of ${mount.server} at ${mountpoint}";
        wantedBy = [ "multi-user.target" ];
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];

        # The directory containing the mountpoint, not the mountpoint itself: a
        # path about to become a mount would make this unit wait for the mount it
        # exists to create.
        unitConfig.RequiresMountsFor = builtins.dirOf mountpoint;

        # Restarting is how this unit waits for a server it cannot connect to
        # yet, so it must not be given up on.
        startLimitBurst = 0;

        # Deliberately without any of the sandboxing options of systemd.
        # ProtectSystem, PrivateTmp and their like each give the unit a mount
        # namespace of its own, and a mount made in there is invisible outside the
        # unit. The service would start, report success and mount something
        # nothing else can use.
        serviceConfig = {
          # The client reports readiness once the mount is made and its signal
          # handlers are installed, so a dependent unit started after this one
          # finds the mount in place, and stopping it unmounts in order.
          Type = "notify";

          ExecStartPre = lib.escapeShellArgs [
            (lib.getExe' pkgs.coreutils "mkdir")
            "-p"
            mountpoint
          ];
          ExecStart = mountCommand mountpoint mount;

          # Backing off instead of hammering: a short outage is retried at once,
          # while a server that is gone for longer is tried once a minute until
          # it replies.
          Restart = "always";
          RestartSec = "2s";
          RestartSteps = 5;
          RestartMaxDelaySec = "1min";

          # Given as an absolute path instead of a PATH lookup. The client passes
          # the mountpoint to this helper, which is what lets the mount be
          # released if the client is killed.
          Environment = [ "FUSERMOUNT_PATH=${lib.getExe' pkgs.fuse3 "fusermount3"}" ];
        };
      }
    ) cfg;
  };
}
