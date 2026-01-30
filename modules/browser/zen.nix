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
            "zen.site-data-panel.show-callout" = false;
            "zen.theme.gradient-legacy-version" = 1;
            "zen.ui.migration.compact-mode-button-added" = true;
            "zen.urlbar.behavior" = "normal";
            "zen.view.compact.enable-at-startup" = false;
            "zen.view.show-newtab-button-border-top" = true;
            "zen.view.show-newtab-button-top" = false;
            "zen.view.use-single-toolbar" = false;
            "zen.view.window.scheme" = 0;
            "zen.workspace.separate-essentials" = false;
            "media.videocontrols.picture-in-picture.enable-when-switching-tabs.enabled" = true;
          };
          extensions.packages =
            with inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system}; [
              ublock-origin
              bitwarden
              sponsorblock
              startpage-private-search
              return-youtube-dislikes
              youtube-shorts-block
              youtube-no-translation
            ];
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