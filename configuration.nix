{
  config,
  foundrixModules,
  foundrixPkgs,
  lib,
  pkgs,
  pkgsUnstable,
  ...
}:
# To save you a few keystores, assuming you only need one user, here's where you can set the username.
let
  userName = "noah";
in
{
  imports = [
    foundrixModules.components.steam
    foundrixModules.config.adb
    foundrixModules.config.direnv
    foundrixModules.config.graphics.cursors.breezex-rosepine
    foundrixModules.config.graphics.fonts.adwaita-sans
    foundrixModules.config.graphics.gtk-dark
    foundrixModules.config.graphics.qt
    foundrixModules.config.home-jdk
    foundrixModules.config.gamescope-session
    foundrixModules.config.linux.sysrq
    foundrixModules.config.shell.zsh.power10k
    foundrixModules.config.virtualisation.podman
    foundrixModules.config.vscode-opinionated
    foundrixModules.profiles.desktop-full
    ./home.nix
  ];

  boot.binfmt.emulatedSystems = lib.mkIf pkgs.stdenv.hostPlatform.isx86_64 [ "aarch64-linux" ];

  environment = {
    systemPackages = with pkgs; [
      duperemove
      gparted
    ];
    variables = {
      BROWSER = "zen-beta";
    };
  };

  fonts = {
    fontconfig.defaultFonts = {
      monospace = [ "Adwaita Mono" ];
      sansSerif = [
        "Adwaita Sans"
        "Noto"
      ];
    };
    packages = with pkgs; [
      adwaita-fonts
      fira
      hasklig
      iosevka
      iosevka-comfy.comfy
      material-icons
      material-symbols
      nerd-fonts.fira-code
      nerd-fonts.hasklug
      roboto
    ];
  };

  foundrix = {
    components = {
      steam = {
        gamescope.enable = true;
      };
    };
    config = {
      home-jdk.jdkPackages = [
        pkgs.jdk17
        pkgs.jdk21
        pkgs.jdk25
      ];
      gamescope-session = {
        enable = true;
        hdr.enable = true;
        refreshRate = 175;
      };
    };
  };

  programs.steam.extraCompatPackages = with pkgsUnstable; [
    proton-ge-bin
    foundrixPkgs.proton-packages.cachyos-x86_64_v4
  ];

  home-manager.users.${userName}.home.stateVersion = "25.11";

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (pkgs.lib.getName pkg) [
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
      "via"
    ];

  security.sudo = {
    enable = true;
  };

  services.tailscale.enable = true;

  system.stateVersion = "25.11";

  # Configure your users here
  users.groups.${userName}.gid = config.users.users.${userName}.uid;

  users.users.${userName} = {
    extraGroups = [ "wheel" ];
    hashedPassword = "$y$j9T$MXSMjuO2SULmBg9oXnbNB/$FnU.BdkloQ4eFdBkLdXMT6F7vM6zXN4QWuzcjgH..s1";
    isNormalUser = true;
    shell = pkgs.zsh;
    uid = 1000;
  };

  # You can also set a root password here
  users.users.root.hashedPassword = config.users.users.${userName}.hashedPassword;
}