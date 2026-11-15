# The document read by voidportd: which directories a namespace shares and where
# guests find them, as typed options, together with the lowering from those
# options into the attribute set written out as TOML.
#
# Typed instead of a freeform attribute set, because voidportd parses its state
# file with unknown fields denied and does not start on a file it cannot parse. A
# field spelled wrong has to fail while the configuration is built. Otherwise it
# fails at the server, after a rebuild has already switched.
#
# A directory is shared at the absolute path it has on the serving host, which is
# what the `voidportd share` command writes into a document. Directories then
# compose into the hierarchy they have on that host instead of colliding on a
# name, and the path used by a guest to open one is the path it has there. A rule
# at the namespace root is not an alternative, because the rule engine treats a
# literal `/` as invalid, so the mount URL used by a guest repeats that same
# absolute path as its subpath.
{ lib }:

let
  inherit (lib) mkOption types;
in
rec {
  # The modes available to a rule, by the name used for one in a configuration.
  # The values are the spellings used for voidport's own ShareMode in the state
  # file, and renderDocument below is the only place that writes them.
  #
  # voidport has a third mode, "hidden", left out here on purpose: it applies to a
  # path inside an attached tree that guests should not see, and every directory
  # declared below is attached as a tree of its own. Hiding one of those from
  # itself shares nothing at all.
  shareModes = {
    readOnly = "ro";
    readWrite = "rw";
  };

  # Whether a mode lets a guest change what it covers. The serving side needs this
  # to work out which paths its service may write to at all.
  grantsWriting = mode: mode == "readWrite";

  directoryType = types.submodule {
    options.mode = mkOption {
      type = types.enum (lib.attrNames shareModes);
      default = "readOnly";
      description = ''
        What guests may do with this directory. Read-only also removes the write
        bits from the permissions shown to them, instead of letting a write be
        attempted and then fail.
      '';
    };
  };

  namespaceType = types.submodule {
    options.directories = mkOption {
      type = types.attrsOf directoryType;
      default = { };
      example = {
        "/srv/artifacts" = { };
      };
      description = ''
        The directories shared by this namespace, keyed by the absolute path each
        one has on this host. That path is also the path a guest opens the
        directory at, so a mount repeats it as the subpath of its URL.
      '';
    };
  };

  tcpListenerType = types.submodule {
    options = {
      address = mkOption {
        type = types.str;
        default = "0.0.0.0";
        description = ''
          Which local addresses accept guests. Every one of them by default,
          because `voidport.serve.firewallInterfaces` sets what can open the
          port, and the bind does not: an address belonging to an interface
          configured late, such as a tailnet address, does not exist yet at boot,
          and a listener that cannot be bound stops the server from starting at
          all.
        '';
      };

      port = mkOption {
        type = types.port;
        example = 9000;
        description = ''
          Which port accepts guests. Deliberately without a default: voidport has
          no default bind, and a default chosen here would be one more value to
          keep in step with the firewall and with every mount that uses it.
        '';
      };
    };
  };

  # The whole document, as pkgs.formats.toml writes it. The keys are voidport's
  # own. Every field treated as optional by the server is left out, so that the
  # defaults applied stay the ones defined upstream: a namespace needs nothing but
  # a name and its rules, and the control socket falls back to the compiled-in
  # /run/voidport/control.sock.
  renderDocument =
    { tcpListeners, namespaces }:
    {
      server.listeners = map (listener: {
        transport = "tcp";
        addr = "${listener.address}:${toString listener.port}";
      }) tcpListeners;

      namespaces = lib.mapAttrsToList (name: namespace: {
        inherit name;
        rules = lib.mapAttrsToList (directory: shared: {
          path = directory;
          target = directory;
          mode = shareModes.${shared.mode};
        }) namespace.directories;
      }) namespaces;
    };
}
