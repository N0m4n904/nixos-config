# Declared non-Steam shortcuts, so emulators and third-party launchers appear in
# the Steam library beside real games - in game mode on the console, and in Big
# Picture or the desktop client anywhere else.
#
# Steam keeps these in shortcuts.vdf, a binary file under the account directory
# which it rewrites whenever it exits. That makes this the one part of the setup
# that cannot be pure configuration: the file has to be edited in place, and only
# while Steam is not running. Everything below is about finding those moments.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.steamShortcuts;
  shortcuts = cfg.entries;


  declared = (pkgs.formats.json { }).generate "steam-shortcuts.json" (
    lib.mapAttrs (_: entry: {
      inherit (entry)
        exe
        startDir
        icon
        launchOptions
        tags
        ;
    }) shortcuts
  );

  incomplete = lib.attrNames (lib.filterAttrs (_: entry: entry.exe == "") shortcuts);

  sync =
    pkgs.writers.writePython3Bin "steam-shortcuts-sync"
      {
        libraries = [ pkgs.python3Packages.vdf ];
        flakeIgnore = [ "E501" ];
      }
      ''
        import binascii
        import json
        import sys
        from pathlib import Path

        import vdf

        STATE_FILE = "shortcuts-managed.json"


        def app_id(exe, name):
            """Steam's identity for a shortcut, and the filename its artwork is
            stored under. Derived from the command, which is why the command wants
            to be a stable path: change it and Steam sees an unrelated new entry
            with its per-game settings and grid images gone."""
            crc = binascii.crc32((exe + name).encode("utf-8")) & 0xFFFFFFFF
            return (crc | 0x80000000) - 2 ** 32


        def shortcut(name, spec):
            exe = '"{}"'.format(spec["exe"])
            return {
                "appid": app_id(exe, name),
                "AppName": name,
                "Exe": exe,
                "StartDir": '"{}"'.format(spec["startDir"]),
                "icon": spec["icon"],
                "ShortcutPath": "",
                "LaunchOptions": spec["launchOptions"],
                "IsHidden": 0,
                "AllowDesktopConfig": 1,
                "AllowOverlay": 1,
                "OpenVR": 0,
                "Devkit": 0,
                "DevkitGameID": "",
                "DevkitOverrideAppID": 0,
                "LastPlayTime": 0,
                "FlatpakAppID": "",
                "tags": {str(i): tag for i, tag in enumerate(spec["tags"])},
            }


        def account_configs(home):
            """Every signed-in account has its own shortcuts file. The two roots are
            the same directory by way of a symlink on most installs, so resolve
            before deduplicating."""
            found = {}
            for root in (home / ".steam" / "steam", home / ".local" / "share" / "Steam"):
                userdata = root / "userdata"
                if not userdata.is_dir():
                    continue
                for account in userdata.iterdir():
                    config = account / "config"
                    if config.is_dir():
                        found[config.resolve()] = None
            return list(found)


        def sync(config, wanted):
            target = config / "shortcuts.vdf"
            by_name = {}
            if target.exists():
                with target.open("rb") as handle:
                    existing = vdf.binary_load(handle).get("shortcuts", {})
                by_name = {entry.get("AppName", ""): entry for entry in existing.values()}

            # Entries dropped from the declaration since the last run are ours to
            # withdraw. Anything that was never declared was added by hand from
            # desktop mode and is left exactly as it is.
            state = config / STATE_FILE
            previously = json.loads(state.read_text()) if state.exists() else []
            for stale in previously:
                if stale not in wanted:
                    by_name.pop(stale, None)

            for name, spec in wanted.items():
                by_name[name] = shortcut(name, spec)

            ordered = {str(i): entry for i, entry in enumerate(by_name.values())}
            scratch = target.with_name(target.name + ".new")
            with scratch.open("wb") as handle:
                vdf.binary_dump({"shortcuts": ordered}, handle)
            scratch.replace(target)
            state.write_text(json.dumps(sorted(wanted), indent=2))
            return len(by_name)


        def main():
            wanted = json.loads(Path(sys.argv[1]).read_text())
            configs = account_configs(Path(sys.argv[2]))
            if not configs:
                # Expected on a console nobody has signed into yet: Steam creates
                # the account directory on first login, and the next time game mode
                # starts there is somewhere to write.
                print("no Steam account directories yet, nothing to do")
                return 0
            for config in configs:
                total = sync(config, wanted)
                print("{}: {} declared, {} in file".format(config, len(wanted), total))
            return 0


        if __name__ == "__main__":
            sys.exit(main())
      '';
in
{
  options.steamShortcuts.user = lib.mkOption {
    type = lib.types.str;
    description = ''
      Account whose Steam library the shortcuts are published into. Every
      signed-in account under that home is updated, since Steam keeps one
      shortcuts file per account.
    '';
  };

  options.steamShortcuts.entries = lib.mkOption {
    default = { };
    description = ''
      Programs to publish into Steam as non-Steam games, keyed by the name Steam
      displays. Declared entries are kept in step with this attribute set;
      shortcuts added by hand in Steam are left alone.
    '';
    example = lib.literalExpression ''
      {
        "Dolphin" = {
          package = pkgs.dolphin-emu;
          tags = [ "Emulator" ];
        };
      }
    '';
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        {
          options = {
            package = lib.mkOption {
              type = lib.types.nullOr lib.types.package;
              default = null;
              description = ''
                Program to publish. Installed system-wide, because the shortcut
                has to name a path that outlives any one image.
              '';
            };

            exe = lib.mkOption {
              type = lib.types.str;
              default = lib.optionalString (
                config.package != null
              ) "/run/current-system/sw/bin/${baseNameOf (lib.getExe config.package)}";
              defaultText = lib.literalExpression ''"/run/current-system/sw/bin/''${mainProgram of package}"'';
              description = ''
                Command Steam runs. Deliberately a path through the current
                system rather than into the store: Steam hashes this to identify
                the shortcut, so a store path would make every update look like a
                brand new game and discard its artwork and controller layout.
              '';
            };

            startDir = lib.mkOption {
              type = lib.types.str;
              default = builtins.dirOf config.exe;
              defaultText = lib.literalExpression "the directory holding exe";
              description = "Working directory Steam launches the program from.";
            };

            icon = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = ''
                Icon shown in the library. A store path is fine here - unlike the
                command, it is not part of the shortcut's identity.
              '';
            };

            launchOptions = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = "Arguments and environment, in Steam's %command% form.";
            };

            tags = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Library categories to file the shortcut under.";
            };
          };
        }
      )
    );
  };

  config = lib.mkIf (shortcuts != { }) {
    assertions = [
      {
        assertion = incomplete == [ ];
        message = ''
          steamShortcuts.entries need either a package or an explicit exe:
          ${lib.concatStringsSep ", " incomplete}
        '';
      }
    ];

    environment.systemPackages = lib.filter (p: p != null) (
      lib.mapAttrsToList (_: entry: entry.package) shortcuts
    );

    systemd.services.steam-shortcuts = {
      description = "Publish declared non-Steam shortcuts into Steam";

      # Ordered against game mode rather than run at boot, because entering it is
      # the moment Steam is reliably not running to write the file back: the
      # switch out of the desktop shuts Steam down first. Both kinds of machine
      # here have that session, so both get the same trigger.
      #
      # Wanted rather than required, so failing to write a shortcut costs the
      # shortcut and not the session.
      before = [ "gamescope-session.service" ];
      wantedBy = [ "gamescope-session.service" ];

      unitConfig = {
        # The home may be a mount of its own - on the console it is an overlay
        # assembled from /var - and writing into it before it appears would put
        # the shortcuts somewhere nothing will ever read. systemd works out which
        # unit that is from the path.
        RequiresMountsFor = config.users.users.${cfg.user}.home;
      };

      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;

        # Steam rewrites shortcuts.vdf from memory when it exits, so editing the
        # file underneath a running client achieves nothing and loses whatever it
        # had. Skipping is the honest outcome - the next entry into game mode
        # will do it - and the switch into game mode shuts Steam down first, so
        # in the ordinary case this passes.
        #
        # A script rather than pgrep directly, because the condition wanted is
        # the negation of what pgrep reports and systemd has no way to invert an
        # exit status. pgrep's own -v inverts which processes are listed, not
        # whether any matched, so it would report success no matter what.
        ExecCondition = pkgs.writeShellScript "steam-not-running" ''
          ! ${lib.getExe' pkgs.procps "pgrep"} -x steam >/dev/null
        '';

        ExecStart = "${lib.getExe sync} ${declared} ${config.users.users.${cfg.user}.home}";
      };
    };
  };
}
