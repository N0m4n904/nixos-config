# Wires Steam's own update button to this console's A/B image updates.
#
# -steamos3 makes Steam believe it is a Steam Deck, so its settings offer to
# update the operating system and it shells out to steamos-update to find out
# whether one is pending. The obvious answer is to say "nothing pending" and be
# done. The better one is to answer honestly: this console really does have an
# update mechanism, and systemd-sysupdate can be asked the same two questions
# Steam is asking. So the Deck's update button ends up driving the store slots,
# and game mode gets to offer updates without anyone leaving it.
#
# (The wizard's *mandatory* update gate is a different hook with a different
# answer - see steamos-mandatory-update.nix.)
#
# Neither question can be answered directly, because both need root and this
# runs inside Steam's container, where sudo is refused outright: the runtime
# sets no_new_privs, so no amount of sudoers configuration will escalate from
# in there. systemctl is the one route out, since it asks systemd over D-Bus and
# is authorised by polkit rather than by the caller's privileges - which is why
# both paths below go through a unit instead of running anything themselves.
#
# Steam reads only the exit status of `check`: 7 means nothing pending, 0 means
# an update is ready.
{
  lib,
  coreutils,
  runCommand,
  systemd,
  writeShellApplication,
  # Written by console-update-check.service; see console-ota.nix.
  availableFile ? "/run/game-console-update-available",
}:

let
  bridge = writeShellApplication {
    name = "steamos-update";

  text = ''
    systemctl=${lib.escapeShellArg (lib.getExe' systemd "systemctl")}

    case "''${1:-}" in
      check)
        # Refresh before answering rather than reporting whatever the hourly
        # timer last saw, so the button reflects the server as it is now. This
        # blocks until the unit finishes, which is the point - the answer is
        # only worth reading afterwards.
        "$systemctl" start console-update-check.service >/dev/null 2>&1 || true

        # The unit writes the version on offer, or nothing at all. Anything
        # there means an update is waiting; an unreadable or empty file means
        # the check could not run, which is reported as "nothing pending"
        # rather than as an update Steam would then fail to apply.
        version=""
        [ -r ${availableFile} ] && read -r version < ${availableFile} || true

        [ -n "$version" ] && exit 0
        exit 7
        ;;

      *)
        # Applying writes a partition, so it goes through the system unit too -
        # see console-ota.nix for the polkit rule that lets game mode start it.
        exec "$systemctl" start systemd-sysupdate.service
        ;;
    esac
  '';

    runtimeInputs = [ coreutils ];
  };
in
# Steam does not call this by name off the PATH. It runs
# /usr/bin/steamos-polkit-helpers/steamos-update by absolute path - on a Deck a
# thin pkexec wrapper around the real thing, which is why it lives in a
# subdirectory of its own. Reached only through the name, the apply half of the
# update button silently did nothing and reported "Updater apply error: 2".
#
# Both names, because `check` is what Steam looks up on the PATH while the apply
# goes to the helper. Nothing here needs pkexec: the work happens in a system
# unit that polkit authorises, so the two names can be the same script.
runCommand "steamos-update"
  {
    meta = bridge.meta // {
      mainProgram = "steamos-update";
    };
  }
  ''
    mkdir -p $out/bin/steamos-polkit-helpers
    ln -s ${lib.getExe bridge} $out/bin/steamos-update
    ln -s ${lib.getExe bridge} $out/bin/steamos-polkit-helpers/steamos-update
  ''
