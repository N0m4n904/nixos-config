{ foundrixModules, mkPerUserHomeManagerModule, pkgs, ... }:
{
  imports = [
    foundrixModules.components.desktop-environments.cosmic
    foundrixModules.config.graphics.gtk-dark
    foundrixModules.config.graphics.themes.adwaita-dark
    (mkPerUserHomeManagerModule __curPos {
      home.packages = with pkgs; [
          cosmic-ext-applet-caffeine
          cosmic-ext-applet-minimon
      ];
    })
  ];

  services.system76-scheduler.enable =  true;

  environment.cosmic.excludePackages = with pkgs; [
    cosmic-edit
  ];
}