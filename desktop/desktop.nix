{
  foundrixModules,
  pkgsUnstable,
  foundrixPkgs,
  pkgs,
  ...
}:

{
  imports = [
    foundrixModules.profiles.desktop-full
    foundrixModules.config.virtualisation.podman
    foundrixModules.config.vscode-opinionated
    foundrixModules.config.graphics.cursors.breezex-rosepine
    foundrixModules.config.graphics.fonts.adwaita-sans
    foundrixModules.config.graphics.gtk-dark
    foundrixModules.config.gamescope-session
    foundrixModules.config.graphics.qt
    foundrixModules.components.steam
    ./home.nix
  ];

  programs.steam.extraCompatPackages = with pkgsUnstable; [
    proton-ge-bin
    foundrixPkgs.proton-packages.cachyos-x86_64_v4
  ];

  foundrix = {
    components = {
      steam = {
        gamescope.enable = true;
      };
    };
    config = {
      gamescope-session = {
        enable = true;
        hdr.enable = true;
        refreshRate = 175;
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
      "teamviewer"
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
}