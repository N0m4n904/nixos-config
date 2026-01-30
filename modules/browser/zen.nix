{
  inputs,
  applyHomeManagerShared,
  ...
}:
let
  mkPluginUrl = id: "https://addons.mozilla.org/firefox/downloads/latest/${id}/latest.xpi";

  mkExtensionEntry = {
    id,
    pinned ? false,
  }: let
    base = {
      install_url = mkPluginUrl id;
      installation_mode = "force_installed";
    };
  in
    if pinned
    then base // {default_area = "navbar";}
    else base;

  mkExtensionSettings = builtins.mapAttrs (_: entry:
    if builtins.isAttrs entry
    then entry
    else mkExtensionEntry {id = entry;});
in
{
  home-manager = applyHomeManagerShared {
    imports = [
      inputs.zen-browser.homeModules.beta
    ];
    programs = {
      zen-browser = {
        enable = true;
        policies = {
          ExtensionSettings = mkExtensionSettings {
            "uBlock0@raymondhill.net" = mkExtensionEntry {
              id = "ublock-origin";
              pinned = true;
            };
            "{446900e4-71c2-419f-a6a7-df9c091e268b}" = mkExtensionEntry {
              id = "bitwarden-password-manager";
              pinned = true;
            };
            "sponsorBlocker@ajay.app" = mkExtensionEntry {
              id = "sponsorblock";
              pinned = false;
            };
            "{762f9885-5a13-4abd-9c77-433dcd38b8fd}" = mkExtensionEntry {
              id = "return-youtube-dislikes";
              pinned = false;
            };
            "{34daeb50-c2d2-4f14-886a-7160b24d66a4}" = mkExtensionEntry {
              id = "youtube-shorts-block";
              pinned = false;
            };
            "{9a3104a2-02c2-464c-b069-82344e5ed4ec}" = mkExtensionEntry {
              id = "youtube-no-translation";
              pinned = false;
            };
          };
        };
        profiles.default = {
          isDefault = true;
          settings = {
            zen = {
              window-sync.enabled = false;
              site-data-panel.show-callout = false;
              theme.gradient-legacy-version = 1;
              ui.migration.compact-mode-button-added = true;
              urlbar.behavior = "normal";
              view = {
                compact. enable-at-startup = false;
                show-newtab-button-border-top = true;
                show-newtab-button-top = false;
                use-single-toolbar = false;
                window.scheme = 0;
              };
              workspace.separate-essentials = false;
            };
            media.videocontrols.picture-in-picture.enable-when-switching-tabs.enabled = true;
          };
          search = {
            force = true;
            default = "Startpage";
            engines = {
              "Startpage" = {
                urls = [{
                  template = "https://www.startpage.com/sp/search";
                  params = [
                    { name = "query"; value = "{searchTerms}"; }
                  ];
                }];
                definedAliases = [ "@sp" "@startpage" ];
              };
            };
          };
        };
      };
    };
  };
}