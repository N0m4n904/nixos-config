{
  foundrixModules,
  pkgsUnstable,
  #foundrixPkgs,
  pkgs,
  config,
  applyHomeManagerShared,
  inputs,
  lib,
  ...
}:

{
  imports = [
    foundrixModules.profiles.desktop-full
    foundrixModules.config.virtualisation.podman
    foundrixModules.config.vscode-opinionated
    foundrixModules.config.graphics.cursors.breezex-rosepine
    foundrixModules.config.graphics.gtk-dark
    foundrixModules.config.gamescope-session
    foundrixModules.config.graphics.qt
    foundrixModules.hardware.peripherals.nsw2-controller
    foundrixModules.components.steam
    ./home.nix
    ../modules/browser/zen.nix
    inputs.joycon-colors.nixosModules.default
  ];

  services.udev.packages = [ pkgsUnstable.dolphin-emu ];

  security.wrappers.bwrap.setuid = lib.mkForce false;

  programs.steam = {
    protontricks.enable = true;
    extraCompatPackages = with pkgsUnstable; [
      #foundrixPkgs.proton-packages.cachyos-x86_64_v4
      proton-ge-bin
      (
        (proton-ge-bin.overrideAttrs (
          prev: final: {
            src = fetchzip {
              url = "https://github.com/CachyOS/proton-cachyos/releases/download/cachyos-11.0-20260521-slr/proton-cachyos-11.0-20260521-slr-x86_64_v3.tar.xz";
              hash = "sha256-Vy4asQ9UfvkD+ZWi+7Le7GjUfMR7QZcGtOQ0msYni7w=";
            };
            pname = "proton-cachyos";
            version = "proton-cachyos-11.0-20260521-slr-x86_64_v3";
          }
        )).override
        { steamDisplayName = "Proton-CachyOS-latest"; }
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
    hardware = {
      peripherals = {
        nsw2-controller.enable = true;
      };
    };
    nixpkgs.allowedUnfreePackageNames = [
      "android-studio"
      "discord"
      "discord-ptb"
      "makemkv"
      "postman"
      "spotify"
      "steam"
      "steam-original"
      "steam-run"
      "steam-unwrapped"
      "teamspeak6-client"
    ];
  };

  environment = {
    systemPackages = with pkgs; [
      gparted
    ];
    interactiveShellInit = ''
      alias claude='NIXPKGS_ALLOW_UNFREE=1 CLAUDE_CODE_NO_FLICKER=1 nix run --impure github:NixOS/nixpkgs/master#claude-code'
    '';
    variables = {
      BROWSER = "zen-beta";
    };
  };

  hardware = {
    joycon-color-change = {
      enable = true;
      gui = true;
    };
  };

  home-manager = applyHomeManagerShared {
    home.file."Desktop/gamescope.desktop" = {
      source = "${config.foundrix.config.gamescope-session.desktopEntry}/share/applications/gamescope-session.desktop";
      executable = true;
    };
  };
}