{
  foundrixModules,
  pkgsUnstable,
  #foundrixPkgs,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    foundrixModules.profiles.desktop-full
    foundrixModules.config.virtualisation.podman
    foundrixModules.config.vscode-opinionated
    foundrixModules.config.graphics.cursors.breezex-rosepine
    foundrixModules.config.graphics.gtk-dark
    foundrixModules.config.graphics.qt
    foundrixModules.hardware.peripherals.nsw2-controller
    foundrixModules.components.steam
    ./home.nix
    ../modules/gaming/controller-touchpad-pointer.nix
    ../modules/gaming/game-mode-desktop-entry.nix
    ../modules/gaming/non-steam-games.nix
    ../modules/gaming/proton-cachyos.nix
    ../modules/browser/zen.nix
    ../modules/overlays/noriskclient-launcher.nix
    inputs.joycon-colors.nixosModules.default
  ];

  # Proton-CachyOS comes from ../modules/gaming/proton-cachyos.nix, which appends
  # itself to this list. It tracks upstream's latest release through the flake
  # lock, so it moves with `nix flake update` rather than by hand.
  programs.steam = {
    protontricks.enable = true;
    extraCompatPackages = [ pkgsUnstable.proton-ge-bin ];
  };

  foundrix = {
    components = {
      steam = {
        gamescope.enable = true;
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

  nixpkgs.config.permittedInsecurePackages = [ "idea-oss-2025.3.4" ];

  environment = {
    systemPackages = with pkgs; [
      gparted
    ];
    interactiveShellInit = ''
      alias claude='NIXPKGS_ALLOW_UNFREE=1 nix run --impure git+https://gitlab.com/xdevs23/claude-code-10x'
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
}
