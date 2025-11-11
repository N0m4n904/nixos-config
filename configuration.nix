{
  foundrixModules,
  lib,
  pkgs,
  config,
  ...
}:
# To save you a few keystores, assuming you only need one user, here's where you can set the username.
let
  userName = "noah";
in
{
  imports = [
    foundrixModules.profiles.desktop-full
    foundrixModules.config.graphics.cursors.breezex-rosepine
    foundrixModules.config.graphics.fonts.adwaita-sans
    foundrixModules.config.graphics.gtk-dark
    foundrixModules.config.graphics.qt
    foundrixModules.config.shell.zsh.power10k
    foundrixModules.config.adb
    foundrixModules.config.linux.sysrq
    foundrixModules.config.virtualisation.docker
    foundrixModules.config.vscode-opinionated
    foundrixModules.components.steam
    foundrixModules.config.direnv
    foundrixModules.config.home-jdk
    ./home.nix
    ./dconf.nix
  ];

  # Configure your users here
  users.users.${userName} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    uid = 1000;
    hashedPassword = "$y$j9T$MXSMjuO2SULmBg9oXnbNB/$FnU.BdkloQ4eFdBkLdXMT6F7vM6zXN4QWuzcjgH..s1";
    shell = pkgs.zsh;
  };
  users.groups.${userName}.gid = config.users.users.${userName}.uid;
  # You can also set a root password here
  users.users.root.hashedPassword = config.users.users.${userName}.hashedPassword;

  # Usually the state version is all you need. There is a separate file for home configuration.
  home-manager.users.${userName}.home.stateVersion = "25.05";

  security.sudo = {
    enable = true;
  };

  fonts = {
    packages = with pkgs; [
      nerd-fonts.fira-code
      nerd-fonts.hasklug
      fira
      adwaita-fonts
      material-icons
      material-symbols
      roboto
      hasklig
      iosevka
      iosevka-comfy.comfy
    ];
    fontconfig.defaultFonts = {
      sansSerif = [
        "Adwaita Sans"
        "Noto"
      ];
      monospace = [ "Adwaita Mono" ];
    };
  };

  environment = {
    systemPackages = with pkgs; [
      duperemove
      gparted
    ];
    variables = {
      BROWSER = "zen-beta";
    };
  };

  boot.binfmt.emulatedSystems = lib.mkIf pkgs.stdenv.hostPlatform.isx86_64 [ "aarch64-linux" ];

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (pkgs.lib.getName pkg) [
      "discord"
      "spotify"
      "steam"
      "steam-original"
      "steam-run"
      "steam-unwrapped"
      "makemkv"
      "android-studio-stable"
      "postman"
      "teamviewer"
      "discord-ptb"
    ];

  services.tailscale.enable = true;

  foundrix = {
    config = {
      shell.zsh.power10k = {
        colors = {
          osIconBackground = "#34ABB1";
          hostBackground = "#348AB1";
          userBackground = "#296A87";
          dirBackground = "#7D74E9";
          dirAnchorBackground = "#6A62C6";
          osIconForeground = "#0f0f0f";
          hostForeground = "#0f0f0f";
          userForeground = "#0f0f0f";
          dirForeground = "#0f0f0f";
          dirAnchorForeground = "#0f0f0f";
        };
      };
      home-jdk.jdkPackages = [
        pkgs.jdk17 pkgs.jdk21 pkgs.jdk23
      ];
    };

    components = {
      desktop-environments = {
        gnome = {
          extensions = with pkgs.gnomeExtensions; [
            vitals
            user-themes
            dash-to-dock
            clipboard-indicator
            caffeine
            transparent-top-bar-adjustable-transparency
            kernel-indicator
            window-is-ready-remover
            pip-on-top
            spotify-controls
          ];
        };
      };
      steam = {
        gamescope.enable = true;
        gamescope.session.enable = true;
      };
    };
  };

  system.stateVersion = "25.05";
}
