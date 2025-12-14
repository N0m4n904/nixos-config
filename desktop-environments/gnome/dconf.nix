{
  applyHomeManagerShared,
  config,
  lib,
  ...
}:
{
  home-manager = applyHomeManagerShared {
    dconf.settings =
      lib.optionalAttrs
        (config.services.desktopManager.gnome.enable or config.services.xserver.desktopManager.gnome.enable)
        {
          "org/gnome/desktop/interface" = {
            accent-color = "blue";
            clock-show-date = false;
            clock-show-seconds = true;
            color-scheme = "prefer-dark";
          };
          "org/gnome/desktop/peripherals/keyboard" = {
            numlock-state = true;
          };
          "org/gnome/desktop/wm/preferences" = {
            button-layout = "appmenu:minimize,maximize,close";
          };
          "org/gnome/mutter" = {
            center-new-windows = true;
            dynamic-workspaces = true;
            edge-tiling = true;
            experimental-features = [ "scale-monitor-framebuffer" ];
            workspaces-only-on-primary = true;
          };
          "org/gnome/settings-daemon/plugins/color" = {
            night-light-schedule-automatic = false;
          };
          "org/gnome/shell" = {
            favorite-apps = [
              "signal.desktop"
              "vesktop.desktop"
              "org.gnome.Nautilus.desktop"
              "org.gnome.Terminal.desktop"
              "codium.desktop"
              "zen-beta.desktop"
              "idea-community.desktop"
              "steam.desktop"
              "spotify.desktop"
            ];
            last-selected-power-profile = "performance";
          };
          "org/gnome/shell/extension/dash-to-dock" = {
            apply-custom-theme = false;
            background-color = "rgb(28,113,216)";
            background-opacity = 0.80000000000000004;
            custom-background-color = false;
            custom-theme-shrink = false;
            dash-max-icon-size = 48;
            disable-overview-on-startup = true;
            dock-position = "BOTTOM";
            extend-height = false;
            height-fraction = 0.90000000000000002;
            icon-size-fixed = false;
            isolate-locations = true;
            preferred-monitor-by-connector = "DP-1";
            running-indicator-style = "DEFAULT";
            show-icons-notifications-counter = false;
            show-mounts = false;
            show-mounts-only-mounted = false;
            transparency-mode = "FIXED";
          };
          "org/gnome/shell/extensions/caffeine" = {
            indicator-position-max = 1;
          };
          "org/gnome/shell/extensions/spotify-controls" = {
            position = "leftmost-right";
          };
          "org/gnome/shell/extensions/vitals" = {
            fixed-widths = false;
            hot-sensors = [
              "_temperature_k10temp_tctl_"
              "_temperature_amdgpu_junction_"
              "_memory_usage_"
              "_processor_frequency_"
              "__network-rx_max__"
              "__network-tx_max__"
            ];
            menu-centered = false;
            position-in-panel = 0;
            show-fan = false;
            show-storage = false;
            show-system = false;
            show-voltage = false;
            update-time = 1;
            use-higher-precision = true;
          };
          "org/gnome/terminal/legacy" = {
            new-terminal-mode = "tab";
          };
          "org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9" = {
            background-color = "rgb(0,0,0)";
            bold-is-bright-color = false;
            cursor-background-color = "rgb(255,255,255)";
            cursor-colors-set = false;
            cursor-foreground-color = "rgb(255,255,255)";
            default-size-columns = 150;
            foreground-color = "rgb(255,255,255)";
            use-theme-colors = false;
            visible-name = "Main";
          };
          "org/gnome/tweaks" = {
            show-extensions-notice = false;
          };
        };
  };
}