{ foundrixModules, pkgs, config, lib, applyHomeManagerShared, ... }:

let
  desktopFile =
    if lib.hasAttrByPath [ "foundrix" "config" "gamescope-session" "desktopEntry" ] config then
      "${config.foundrix.config.gamescope-session.desktopEntry}/share/applications/gamescope-session.desktop"
    else
      null;
in
{
  imports = [
    ./dconf.nix
    foundrixModules.components.desktop-environments.gnome
    foundrixModules.config.graphics.gtk-dark
    foundrixModules.config.graphics.themes.adwaita-dark
  ];

  device.crossCompile = false;

  foundrix.components.desktop-environments.gnome = {
    extensions = with pkgs.gnomeExtensions; [
      caffeine
      clipboard-indicator
      dash-to-dock
      desktop-icons-ng-ding
      kernel-indicator
      pip-on-top
      spotify-controls
      transparent-top-bar-adjustable-transparency
      user-themes
      vitals
      window-is-ready-remover
      hide-top-bar
    ];
  };

  home-manager = applyHomeManagerShared {
    home.file = lib.mkIf (desktopFile != null && builtins.pathExists desktopFile) {
      "Desktop/gamescope.desktop" = {
        source = desktopFile;
        executable = true;
      };
    };
  };
}
