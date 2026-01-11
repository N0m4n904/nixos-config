{
  foundrixModules,
  pkgsUnstable,
  foundrixPkgs,
  pkgs,
  lib,
  config,
  applyHomeManagerShared,
  ...
}:

let
  desktopFile =
    if lib.hasAttrByPath [ "foundrix" "config" "gamescope-session" "desktopEntry" ] config then
      "${config.foundrix.config.gamescope-session.desktopEntry}/share/applications/gamescope-session.desktop"
    else
      null;
in
{
  imports = [
    foundrixModules.profiles.desktop-full
    foundrixModules.config.virtualisation.podman
    foundrixModules.config.vscode-opinionated
    foundrixModules.config.graphics.cursors.breezex-rosepine
    foundrixModules.config.graphics.gtk-dark
    foundrixModules.config.gamescope-session
    foundrixModules.config.graphics.qt
    foundrixModules.components.steam
    ./home.nix
  ];

  programs.steam = {
    protontricks.enable = true;
    extraCompatPackages = with pkgsUnstable; [
      foundrixPkgs.proton-packages.cachyos-x86_64_v4
      proton-ge-bin
      (
        (proton-ge-bin.overrideAttrs (
          prev: final: {
            src = fetchzip {
              url = "https://github.com/CachyOS/proton-cachyos/releases/download/cachyos-10.0-20260101-slr/proton-cachyos-10.0-20260101-slr-x86_64_v4.tar.xz";
              hash = "sha256-/dJDBxUAI3FpOZtCVoNsrhBV6QTrksnUdTH7ZdnAZZY=";
            };
            pname = "proton-cachyos";
            version = "proton-cachyos-10.0-20260101-slr-x86_64_v4";
          }
        )).override
        { steamDisplayName = "Proton-CachyOS-local"; }
      )
    ];
  };

  foundrix = {
    components = {
      steam = {
        gamescope.enable = true;
        gamescope.session.enable = true;
      };
    };
    nixpkgs.allowedUnfreePackageNames = [
      "android-studio-stable"
      "discord"
      "discord-ptb"
      "makemkv"
      "postman"
      "spotify"
      "steam"
      "steam-original"
      "steam-run"
      "steam-unwrapped"
    ];
  };

  environment = {
    systemPackages = with pkgs; [
      gparted
    ];
    variables = {
      BROWSER = "zen-beta";
    };
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