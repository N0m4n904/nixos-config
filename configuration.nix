{
  config,
  foundrixModules,
  lib,
  pkgs,
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
    foundrixModules.config.linux.sysrq
    foundrixModules.config.shell.zsh.power10k
    foundrixModules.config.virtualisation.docker
    foundrixModules.config.vscode-opinionated
    foundrixModules.profiles.desktop-full
    ./dconf.nix
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
      desktop-environments = {
        gnome = {
          extensions = with pkgs.gnomeExtensions; [
            caffeine
            clipboard-indicator
            dash-to-dock
            kernel-indicator
            pip-on-top
            spotify-controls
            transparent-top-bar-adjustable-transparency
            user-themes
            vitals
            window-is-ready-remover
          ];
        };
      };
      steam = {
        gamescope.enable = true;
        gamescope.session.enable = true;
      };
    };
    config = {
      home-jdk.jdkPackages = [
        pkgs.jdk17
        pkgs.jdk21
        pkgs.jdk23
      ];
      shell.zsh.power10k = {
        colors = {
          dirAnchorBackground = "#6A62C6";
          dirAnchorForeground = "#0f0f0f";
          dirBackground = "#7D74E9";
          dirForeground = "#0f0f0f";
          hostBackground = "#348AB1";
          hostForeground = "#0f0f0f";
          osIconBackground = "#34ABB1";
          osIconForeground = "#0f0f0f";
          userBackground = "#296A87";
          userForeground = "#0f0f0f";
        };
      };
    };
  };

  home-manager.users.${userName}.home.stateVersion = "25.05";

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
    ];

  security.sudo = {
    enable = true;
  };

  services.tailscale.enable = true;

  system.stateVersion = "25.05";

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