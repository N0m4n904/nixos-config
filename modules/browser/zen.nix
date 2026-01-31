{
  inputs,
  applyHomeManagerShared,
  pkgs,
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
        profiles.default = rec {
          containersForce = true;
          containers = {
            Default = {
              color = "blue";
              id = 1;
            };
          };
          spacesForce = true;
          spaces = {
              "Default" = {
                id = "1a03eb2f-7d2d-41d4-a527-9abcc75f46b8";
                position = 1000;
                container = containers.Default.id;
              };
            };
          pinsForce = true;
          pins = {
              "GitHub" = {
                id = "7c3743cd-fd67-4e93-8d58-52a1c50f7fa4";
                container = containers.Default.id;
                url = "https://github.com";
                isEssential = true;
                position = 101;
              };
              "YouTube" = {
                id = "eb7870a6-ca65-4341-bc7f-a2bb0214041f";
                container = containers.Default.id;
                url = "https://www.youtube.com";
                isEssential = true;
                position = 102;
              };
              "Twitch" = {
                id = "e93b112c-67af-44ce-b781-c3ca1d41191c";
                container = containers.Default.id;
                url = "https://www.twitch.tv/mahluna";
                isEssential = true;
                position = 103;
              };
            };
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
          mods = [
            "f4866f39-cfd6-4498-ab92-54213b8279dc" # Animations Plus
            "d8b79d4a-6cba-4495-9ff6-d6d30b0e94fe" # Better Active Tab
            "a6335949-4465-4b71-926c-4a52d34bc9c0" # Better Find Bar
            "1e9f3101-210b-4ff5-8830-434e4919100d" # Better Letterboxing
            "664c54f9-d97d-410b-a479-23dd8a08a628" # Better Tab Indicators
            "f7c71d9a-bce2-420f-ae44-a64bd92975ab" # Better Unloaded Tabs
            "906c6915-5677-48ff-9bfc-096a02a72379" # Floating Status Bar
            "6c122084-c4ec-4c9e-8cc5-3d87c3a089cb" # NavBar Margin
            "bc25808c-a012-4c0d-ad9a-aa86be616019" # sleek border
            "79dde383-4fe7-404a-a8e6-9be440022542" # Tidy Popup
            "03a8e7ef-cf00-4f41-bf24-a90deeafc9db" # Zen Colored Picker
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