# Stops a gamepad touchpad from driving the mouse cursor while a game runs.
#
# The kernel's hid-playstation driver splits a DualSense into several input
# devices, one of them a plain touchpad ("... Controller Touchpad"). Mutter picks
# it up like any other touchpad, so a finger on the pad moves the pointer for the
# whole session - including over a fullscreen game, which is exactly where you
# want the pad to be a pad and nothing else.
#
# Games do not lose the touchpad by this. Steam reads the controller from its
# hidraw node, a separate transport carrying the raw HID reports with finger
# positions and the click, and Steam Input hands those to the game. Only the
# cursor path is cut.
#
# GNOME has no per-device touchpad setting - the peripherals schema is a single
# fixed path - so this is the session-wide touchpad switch, flipped only for the
# duration of a game and only while one of the controllers named below is
# attached, identified by the HID ids the kernel reports for it rather than by
# name, so that nothing else answering to "Touchpad" can trip it. On
# a laptop that also silences the internal touchpad for that window, which is
# tolerable: the controller is in your hands anyway.
{ lib, pkgs, ... }:

let
  schemas = pkgs.gsettings-desktop-schemas;

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

  # The previous value is remembered rather than assumed, so ending a game
  # restores what was there instead of unconditionally switching touchpads on.
  # $XDG_RUNTIME_DIR is per-session and cleared at logout, which is the right
  # lifetime for it.
  controller-touchpad-pointer = pkgs.writeShellApplication {
    name = "controller-touchpad-pointer";
    # coreutils as much as glib: gamemoded hands the hook a PATH containing
    # nothing but pkexec, so even cat and rm have to be brought along.
    runtimeInputs = [
      pkgs.coreutils
      pkgs.glib
    ];
    text = ''
      # Both pinned rather than inherited. gamemoded passes the session's
      # environment through, but a GSettings write with no dconf backend loaded
      # goes to an in-memory one and reports success, so leaving either of these
      # to chance buys a failure that looks like nothing happening at all.
      export GSETTINGS_SCHEMA_DIR=${schemas}/share/gsettings-schemas/${schemas.name}/glib-2.0/schemas
      export GIO_EXTRA_MODULES=${pkgs.dconf.lib}/lib/gio/modules

      schema=org.gnome.desktop.peripherals.touchpad
      state=''${XDG_RUNTIME_DIR:-/tmp}/controller-touchpad-pointer.state

      # ${lib.concatStringsSep ", " (lib.attrValues touchpadControllers)}
      controller_touchpad_attached() {
        local device vendor product
        for device in /sys/class/input/input*; do
          [ -r "$device/id/vendor" ] || continue
          read -r vendor < "$device/id/vendor" || continue
          read -r product < "$device/id/product" || continue
          case "$vendor:$product" in
            ${lib.concatStringsSep "|" (lib.attrNames touchpadControllers)}) ;;
            *) continue ;;
          esac
          # Narrows the controller's several nodes down to the pointer one.
          case "$(cat "$device/name")" in
            *Touchpad) return 0 ;;
          esac
        done
        return 1
      }

      case "''${1-}" in
        off)
          controller_touchpad_attached || exit 0
          [ -e "$state" ] || gsettings get "$schema" send-events > "$state"
          gsettings set "$schema" send-events disabled
          # Read back: the write is the whole point of the hook, and a failed one
          # is otherwise indistinguishable from success.
          if [ "$(gsettings get "$schema" send-events)" != "'disabled'" ]; then
            echo "touchpad send-events did not take - is the dconf backend reachable?" >&2
            exit 1
          fi
          ;;
        on)
          # Keyed on having changed something, not on the controller still being
          # attached - unplugging it mid-game must not strand the setting.
          [ -e "$state" ] || exit 0
          gsettings set "$schema" send-events "$(cat "$state")"
          rm -f "$state"
          ;;
        *)
          echo "usage: controller-touchpad-pointer off|on" >&2
          exit 64
          ;;
      esac
    '';
  };
in

{
  environment.systemPackages = [ controller-touchpad-pointer ];

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
