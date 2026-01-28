{
  inputs,
  applyHomeManagerShared,
  pkgs,
  ...
}:
{
  home-manager = applyHomeManagerShared {
    imports = [
      inputs.zen-browser.homeModules.beta
    ];
    programs = {
      zen-browser = {
        enable = true;
        profiles.default = {
          isDefault = true;
          settings = {
            "zen.window-sync.enabled" = false;
            "media.videocontrols.picture-in-picture.enable-when-switching-tabs.enabled" = true;
          };
          extensions.packages =
            with inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system}; [
              ublock-origin
              bitwarden
            ];
        };
      };
    };
  };
}