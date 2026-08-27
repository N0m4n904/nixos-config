# Stops a gamepad touchpad from driving the mouse cursor while a game runs.
#
# The kernel's hid-playstation driver splits a DualSense into several input
# devices, one of them a plain touchpad. Mutter picks it up like any other, so a
# finger on the pad moves the pointer for the whole session - including over a
# fullscreen game, which is exactly where you want the pad to be a pad and
# nothing else.
#
# Games do not lose the touchpad by this. Steam reads the controller from its
# hidraw node, a separate transport carrying the raw HID reports with finger
# positions and the click, and Steam Input hands those to the game. Only the
# cursor path is cut.
#
# The cut is made at the device: writing its inhibited flag tells the kernel to
# stop delivering that one device's events to anybody. Which is the reason for
# going below the desktop rather than asking it nicely - GNOME has no per-device
# touchpad setting, only a session-wide switch that would take a laptop's
# built-in pad down with it, and it is the wrong layer besides, being unheard of
# by the gamescope session where these machines do much of their gaming.
{
  lib,
  pkgs,
  ...
}:

let
  # HID vendor:product of the controllers whose touchpad this applies to, as the
  # kernel reports them in an input device's id/ attributes - lowercase, four
  # digits, and the same over USB and Bluetooth, since they name the HID device
  # rather than the transport. Every node a controller creates carries them, so
  # they say which controller is attached and the node name still has to say
  # which of its nodes is the pad.
  touchpadControllers = {
    "054c:0ce6" = "DualSense";
    "054c:0df2" = "DualSense Edge";
  };

  # Nothing on PATH, deliberately: gamemoded runs the hook with a PATH holding
  # only pkexec, and a script built from shell builtins alone cannot be caught
  # out by that.
  controller-touchpad-pointer = pkgs.writeShellApplication {
    name = "controller-touchpad-pointer";
    text = ''
      # ${lib.concatStringsSep ", " (lib.attrValues touchpadControllers)}
      matching_touchpads() {
        local device vendor product name
        for device in /sys/class/input/input*; do
          [ -r "$device/id/vendor" ] || continue
          read -r vendor < "$device/id/vendor" || continue
          read -r product < "$device/id/product" || continue
          case "$vendor:$product" in
            ${lib.concatStringsSep "|" (lib.attrNames touchpadControllers)}) ;;
            *) continue ;;
          esac
          # Narrows the controller's several nodes down to the pointer one.
          read -r name < "$device/name" || continue
          case "$name" in
            *Touchpad) printf '%s\n' "$device/inhibited" ;;
          esac
        done
      }

      # No record is kept of what was inhibited. The flag lives with the device
      # and defaults to clear, so a controller unplugged mid-game takes its state
      # with it and comes back uninhibited - there is nothing left to restore
      # that re-reading the present devices does not already answer.
      set_inhibited() {
        local wanted=$1 attribute readback
        while read -r attribute; do
          if [ ! -w "$attribute" ]; then
            echo "$attribute is not writable - has udev seen this controller since the rule was installed?" >&2
            exit 1
          fi
          printf '%s\n' "$wanted" > "$attribute"
          # Read back: inhibiting the device is the whole point of the hook, and
          # a write that did not land is otherwise indistinguishable from one
          # that did.
          read -r readback < "$attribute"
          if [ "$readback" != "$wanted" ]; then
            echo "$attribute did not take the value $wanted" >&2
            exit 1
          fi
        done < <(matching_touchpads)
      }

      case "''${1-}" in
        off) set_inhibited 1 ;;
        on) set_inhibited 0 ;;
        *)
          echo "usage: controller-touchpad-pointer off|on" >&2
          exit 64
          ;;
      esac
    '';
  };

  # udev grants the device node's permissions, not a sysfs attribute's, so the
  # one attribute this needs is handed to the input group by hand - the same
  # group that already owns the event node the flag governs.
  inhibitableBy = lib.concatMapStringsSep "\n" (
    id:
    let
      inherit (lib) elemAt splitString;
      parts = splitString ":" id;
    in
    ''# ${touchpadControllers.${id}}''
    + "\n"
    + lib.concatStringsSep ", " [
      ''ACTION=="add"''
      ''SUBSYSTEM=="input"''
      ''KERNEL=="input[0-9]*"''
      ''ATTR{id/vendor}=="${elemAt parts 0}"''
      ''ATTR{id/product}=="${elemAt parts 1}"''
      ''ATTR{name}=="*Touchpad"''
      ''RUN+="${pkgs.coreutils}/bin/chgrp input /sys%p/inhibited"''
      ''RUN+="${pkgs.coreutils}/bin/chmod g+w /sys%p/inhibited"''
    ]
  ) (lib.attrNames touchpadControllers);
in

{
  environment.systemPackages = [ controller-touchpad-pointer ];

  services.udev.extraRules = inhibitableBy;

  programs.gamemode = {
    enable = true;

    # Absolute because gamemoded runs these itself rather than through a shell,
    # and its unit carries a PATH holding only pkexec.
    #
    # The system path rather than the store path, though gamemode.ini is a Nix
    # file and the store path is right there. gamemoded decides whether to
    # re-read its config by comparing the file's mtime, and every file in the
    # store carries the same epoch timestamp - so a rebuild that changes this
    # file changes nothing gamemoded can observe, and it keeps running whatever
    # it loaded at startup. Naming a path that stays put makes the file's
    # contents constant across rebuilds, and the question never arises.
    settings.custom = {
      start = "/run/current-system/sw/bin/controller-touchpad-pointer off";
      end = "/run/current-system/sw/bin/controller-touchpad-pointer on";
    };
  };
}
