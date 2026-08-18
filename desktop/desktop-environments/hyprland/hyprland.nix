{
  applyHomeManagerShared,
  foundrixModules,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  systemctl = lib.getExe' pkgs.systemd "systemctl";
  loginctl = lib.getExe' pkgs.systemd "loginctl";
  cliphist = lib.getExe pkgs.cliphist;
  wlCopy = lib.getExe' pkgs.wl-clipboard "wl-copy";
  uwsm = lib.getExe pkgs.uwsm;

  # Mirrors the $mainMod SHIFT+V binding foundrix installs, so the bar's clipboard
  # button and the keybinding open the same picker.
  clipboardHistoryCommand = lib.concatStringsSep " " [
    "${cliphist} list |"
    "wofi --gtk-dark --normal-window -i --dmenu -p 'Search clipboard history…' -M multi-contains -i |"
    "${cliphist} decode |"
    wlCopy
  ];

  # GNOME also reaches graphical-session.target, so anything hung off it would come
  # up during a GNOME login too - a second polkit agent, a workspace daemon polling a
  # compositor that isn't there, a bar drawn over GNOME Shell. Hyprland-side units are
  # therefore pulled in by a target of their own, which only Hyprland starts.
  sessionTarget = "hyprland-session.target";
  boundToSession.Install.WantedBy = lib.mkForce [ sessionTarget ];
in
{
  imports = [
    foundrixModules.components.desktop-environments.hyprland
    foundrixModules.components.gui.quickshell
    # Imported here rather than alongside the other overlays because it exists purely
    # to undo an assumption this session breaks.
    ../../../modules/overlays/signal-password-store.nix
  ];

  # foundrix's hyprland component brings up greetd, whose unit is aliased to
  # display-manager.service - the unit GDM already owns, so enabling both breaks
  # activation. Hyprland is an additional session on this host rather than a
  # replacement, so GDM stays the display manager and offers "Hyprland (UWSM)"
  # in its session picker.
  services.greetd.enable = lib.mkForce false;

  # NetworkState reads the network through "jc nmcli device status" and
  # "jc ip route get", so without jc on PATH the network panel and its tiles have
  # nothing to parse and come up empty. nmcli and ip are already present.
  environment.systemPackages = [ pkgs.jc ];

  nix.settings = {
    substituters = [ "https://hyprland.cachix.org" ];
    trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
  };

  foundrix.components = {
    desktop-environments.hyprland = {
      browser = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.beta;
      fileManager = pkgs.nautilus;
      terminal = pkgs.gnome-terminal;

      # Matched by description, not connector: the ultrawide and the ViewSonic come up
      # as DP-2/DP-3 depending on which port each cable lands in, and there is no DP-1
      # on this machine at all. Descriptions are cut before the serial because '#'
      # opens a comment in hyprlang.
      #
      # Positions are explicit rather than "auto", which merely lays panels out in the
      # order Hyprland happens to process them. Left to right, vertically centred on
      # the taller middle panel:
      #
      #   0,180        1920,0                     5360,180
      #   ViewSonic    Dell AW3423DW (ultrawide)  BenQ
      #   1920x1080    3440x1440                  1920x1080
      #
      # Only the ViewSonic opts into VRR. The Dell is the AW3423DW, the variant with a
      # hardware G-Sync module, which an AMD GPU cannot drive properly - leaving VRR on
      # makes it flicker. The BenQ reports no VRR capability at all.
      monitors = [
        "desc:ViewSonic Corporation XG2401 SERIES,1920x1080@144,0x180,1,vrr,1"
        "desc:Dell Inc. Dell AW3423DW,3440x1440@175,1920x0,1"
        "desc:BNQ BenQ EW2440L,1920x1080@60,5360x180,1"
      ];

      # The bar reads its workspace state over Hyprland's IPC socket, which changes
      # identity when the compositor's socket is re-created.
      hyprWorkspacedOnReconnectRestart = "quickshell-topbar.service";

      extraConfig = ''
        exec-once = ${systemctl} --user start ${sessionTarget}

        # Tapping the modifier on its own opens the launcher, the way tapping Super
        # opens the overview in GNOME. bindr fires on release, so holding Super for a
        # combination does not trigger it.
        bindr = $mainMod, SUPER_L, exec, $menu --show drun -p 'Search applications…' -M multi-contains -i -O alphabetical

        # GNOME-like windowing: nothing is tiled. Every window opens floating and is
        # positioned by dragging it, so the layout is never rearranged underneath you.
        windowrule = float on, match:class .*

        # Hyprland itself draws no decorations, so the title bar every window is
        # dragged by comes from hyprbars.
        plugin {
          hyprbars {
            bar_height = 40
            bar_color = rgb(303030)
            col.text = rgb(ffffff)
            bar_text_size = 12
            bar_text_font = Adwaita Sans
            bar_text_align = center
            bar_buttons_alignment = right
            bar_padding = 12
            bar_button_padding = 10
            bar_part_of_window = true
            bar_precedence_over_border = true
            inactive_button_color = rgb(3d3d3d)
            on_double_click = hyprctl dispatch fullscreen 1

            # Buttons are laid out right to left, so declaring close first puts the
            # row in GNOME's order: minimise, maximise, close. "size" is the button's
            # diameter in pixels, centred vertically in the bar, so it has to grow
            # with bar_height rather than staying fixed.
            #
            # Hyprland has no minimise - a window is on a workspace or it is nowhere -
            # so the closest equivalent is parking it on a special workspace. Without
            # the $mainMod+N binding below there would be no way back to it.
            hyprbars-button = rgb(4d4d4d), 20, ✕, hyprctl dispatch killactive, rgb(ffffff)
            hyprbars-button = rgb(4d4d4d), 20, □, hyprctl dispatch fullscreen 1, rgb(ffffff)
            hyprbars-button = rgb(4d4d4d), 20, −, hyprctl dispatch movetoworkspacesilent special:minimized, rgb(ffffff)
          }
        }

        # Retrieve anything sent away by the minimise button.
        bind = $mainMod, N, togglespecialworkspace, minimized

        # Only windows that genuinely draw their own header are excluded. Being a
        # Wayland client is not enough to tell: GTK4/libadwaita apps draw a header bar,
        # but GTK3 ones like gnome-terminal ask the compositor for decorations instead
        # and end up bare if hyprbars skips them. There is no rule matcher for "client
        # requested server-side decorations", so this stays an explicit list.
        windowrule {
          name = launcher-no-bar
          match:class = ^(wofi)$
          hyprbars:no_bar = true
        }

        windowrule {
          name = pip-no-bar
          match:title = ^(Picture-in-Picture)$
          hyprbars:no_bar = true
        }

        # Zen deliberately keeps its hyprbars bar. It draws window buttons of its own,
        # but they are not a working substitute: minimise is a concept Hyprland does
        # not have, and Zen exposes no draggable title bar region even with
        # browser.tabs.inTitlebar forced on - verified by it staying put while
        # "hyprctl dispatch moveactive" moved it fine. With the modifier drag shortcut
        # gone, a bar is the only thing left that can move the window.
      '';
    };

    gui.quickshell.instances.topbar = {
      configPath = ./quickshell/topbar;
      modules.common = ./quickshell/common;

      # The shell resolves no binaries itself: every action it can trigger arrives as
      # a store path, so a missing tool fails the build instead of a button.
      environment = {
        # The bar and dock belong on the main screen only, matching Dash to Dock's
        # multi-monitor being off. Matched on part of the model rather than the
        # connector, which is not stable across cable moves.
        QS_BAR_SCREEN = "AW3423DW";
        QS_DOCK_SCREEN = "AW3423DW";

        # The same pinned applications GNOME's dash shows, from one shared list.
        QS_DOCK_APPS = lib.concatStringsSep ":" (import ../../favourite-apps.nix);

        QS_LAUNCHER_COMMAND = "wofi --gtk-dark --normal-window -i --show drun -p 'Search applications…' -M multi-contains -i -O alphabetical";

        QS_CLIPBOARD_COMMAND = clipboardHistoryCommand;
        QS_LOCK_COMMAND = "${loginctl} lock-session";
        QS_LOGOUT_COMMAND = "${uwsm} stop";
        QS_REBOOT_COMMAND = "${systemctl} reboot";
        QS_POWEROFF_COMMAND = "${systemctl} poweroff";
      };
    };
  };

  home-manager = applyHomeManagerShared {
    wayland.windowManager.hyprland = {
      plugins = [ inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system}.hyprbars ];

      settings = {
        # GNOME focuses on click; foundrix defaults to focus-follows-mouse, which makes
        # keystrokes land in whatever the pointer happens to be resting over.
        input.follow_mouse = lib.mkForce 0;

        # Off globally so a VRR-capable panel only gets it by opting in through its
        # monitor rule. The reverse - on globally, off per monitor - would leave the
        # G-Sync Dell flickering if the per-monitor value lost the merge.
        misc.vrr = lib.mkForce 0;

        # Left on deliberately, which is also the default. Compositing the cursor
        # instead was tried to chase pointer lag on the ultrawide, and it cost a
        # permanent second cursor: with the plane unclaimed, whatever image the
        # greeter left on it stays frozen on screen for the whole session. The lag
        # turned out not to need this.
        cursor.no_hardware_cursors = false;

        # Windows are moved by dragging their title bar, so the modifier shortcut is
        # redundant. Resize stays: window edges are draggable too, but the shortcut is
        # far easier to hit on a floating layout.
        bindm = lib.mkForce [
          "$mainMod, mouse:273, resizewindow"
        ];

        # Restated for two reasons. xray off, because with it on the blur samples only
        # the wallpaper and ignores windows - and with no wallpaper engine running the
        # surfaces would frost over plain black, so their transparency would buy
        # nothing. And ignore_alpha above zero, because these surfaces are wider than
        # what they draw: the dock is a centred pill on a full-width layer, so blurring
        # every pixel frosts the empty space beside it into a band across the screen.
        # The threshold sits below the surfaces' own alpha and above nothing at all.
        layerrule = lib.mkForce [
          "ignore_alpha 0.4, blur on, xray off, match:namespace topbar"
          "ignore_alpha 0.4, blur on, xray off, match:namespace quickshell"
        ];

        # Restated rather than extended so foundrix's "suppress_event maximize" can be
        # dropped. That rule makes Hyprland ignore every client's own maximize request,
        # which is right for a tiling layout but means the maximize button a GTK app
        # draws in its own header does nothing, and double-clicking a header to
        # maximise does nothing either. The rest of the list is foundrix's, verbatim.
        windowrule = lib.mkForce [
          "float on, size 640 360, match:title ^(Picture-in-Picture)$"
          "no_blur on, match:xwayland 1"
          "stay_focused on, match:class ^(wofi)$"
        ];
      };
    };

    systemd.user = {
      targets.hyprland-session.Unit = {
        Description = "Hyprland session";
        BindsTo = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };

      services = {
        # hypridle binds ext-idle-notifier-v1, which GNOME does not implement, so
        # without this it crash-loops for the whole length of a GNOME session.
        hypridle = boundToSession;
        hyprpolkitagent = boundToSession;
        hypr-workspaced = boundToSession;
        quickshell-topbar = boundToSession;
      };
    };
  };
}
