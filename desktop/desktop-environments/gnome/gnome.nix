{ foundrixModules, pkgs, ... }:

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
      pip-on-top
      spotify-controls
      transparent-top-bar-adjustable-transparency
      user-themes
      vitals
      window-is-ready-remover
      hide-top-bar
    ];
  };
}
