{
  inputs,
  applyHomeManagerShared,
  pkgs,
  config,
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

  base64Decode = encoded:
    builtins.readFile (pkgs.runCommand "decode" {} ''
      echo "${encoded}" | ${pkgs.coreutils}/bin/base64 -d > $out
    '');
in
{
  home-manager = applyHomeManagerShared {
    imports = [
      inputs.zen-browser.homeModules.beta
    ];
    programs = {
      zen-browser = {
        enable = true;
        policies = let
            mLockedAttrs = builtins.mapAttrs (_: value: {
              Value = value;
              Status = "locked";
            });
          in {
          EnableTrackingProtection = {
            Value = true;
            Locked = true;
            Cryptomining = true;
            Fingerprinting = true;
          };
          Preferences = mLockedAttrs {
          };
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
            "zen.window-sync.enabled" = false;
            "zen.site-data-panel.show-callout" = false;
            "zen.theme.gradient-legacy-version" = 1;
            "zen.ui.migration.compact-mode-button-added" = true;
            "zen.urlbar.behavior" = "normal";
            "zen.view.compact. enable-at-startup" = false;
            "zen.view.show-newtab-button-border-top" = true;
            "zen.view.show-newtab-button-top" = false;
            "zen.view.use-single-toolbar" = false;
            "zen.view.window.scheme" = 0;
            "zen.workspace.separate-essentials" = false;
            "zen.welcome-screen.seen" = true;
            "media.videocontrols.picture-in-picture.enable-when-switching-tabs.enabled"= true;
            "browser.toolbars.bookmarks.visibility" = "always";
            "browser.bookmarks.restore_default_bookmarks" = false;
            "browser.bookmarks.addedImportButton" = true;
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
          bookmarks = {
            force = true;
            settings = [
              {
                name = "Bookmarks";
                toolbar = true;
                bookmarks = [
                  {
                    name = "Home Assistant";
                    url = base64Decode "aHR0cDovLzE5Mi4xNjguMTc4LjE1NDo4MTIzL25vYWgtemltbWVyL2NsaW1hdGU=";
                  }
                  {
                    name = "Portainer | local";
                    url = base64Decode "aHR0cHM6Ly8xOTIuMTY4LjE3OC4xNTc6OTQ0My8jIS8zL2RvY2tlci9jb250YWluZXJz";
                  }
                  {
                    name = "Pi-hole";
                    url = base64Decode "aHR0cDovLzE5Mi4xNjguMTc4LjE1Ny9hZG1pbg==";
                  }
                  {
                    name = "Vaultwarden Web";
                    url = base64Decode "aHR0cHM6Ly93YXJkZW4ubm9uZXR3b3IuY2MvIy9sb2dpbg==";
                  }
                  {
                    name = "FRITZ!Box";
                    url = "http://fritz.box";
                  }
                  {
                    name = "LTE Stick";
                    url = base64Decode "aHR0cDovLzE5Mi4xNjguMC4xL2luZGV4Lmh0bWw=";
                  }
                  {
                    name = "GitLab";
                    url = "https://gitlab.com/N0m4n904";
                  }
                  {
                    name = "halogenOS";
                    bookmarks = [
                      {
                        name = "halogenOS";
                        url = "https://halogenos.org";
                      }
                      {
                        name = "halogenOS GitLab";
                        url = "https://git.halogenos.org/halogenOS";
                      }
                      {
                        name = "halogenOS - buildkite";
                        url = "https://buildkite.com/halogenos";
                      }
                    ];
                  }
                  {
                    name = "Pong";
                    bookmarks = [
                      {
                        name = "Pong - Development";
                        url = "https://github.com/Pong-Development";
                      }
                      {
                        name = "Nothing Phone 2 Development";
                        url = "https://github.com/Nothing-phone-2-Development";
                      }
                      {
                        name = "Flashable Firmware";
                        url = "https://github.com/spike0en/pong_flashable_firmware";
                      }
                      {
                        name = "Nothing Archive";
                        url = "https://github.com/spike0en/nothing_archive/releases";
                      }
                      {
                        name = "android12-5.10-lts";
                        url = "https://android-review.googlesource.com/q/project:kernel/common+branch:android12-5.10-lts";
                      }
                      {
                        name = "LOS/kernel_qcom_sm8450";
                        url = "https://review.lineageos.org/q/project:LineageOS/android_kernel_qcom_sm8450";
                      }
                    ];
                  }
                ];
              }
            ];
          };
        };
      };
    };
  };
}