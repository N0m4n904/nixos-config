{
  config,
  foundrixModules,
  lib,
  pkgs,
  options,
  ...
}:
# To save you a few keystores, assuming you only need one user, here's where you can set the username.
let
  userName = "noah";
in
{
  imports = [
    foundrixModules.config.adb
    foundrixModules.config.direnv
    foundrixModules.config.home-jdk
    foundrixModules.config.linux.sysrq
    foundrixModules.config.shell.zsh.power10k
    foundrixModules.config.home-manager
    foundrixModules.config.graphics.fonts.adwaita-sans
    ./home.nix
  ];

  boot.binfmt.emulatedSystems = lib.mkIf pkgs.stdenv.hostPlatform.isx86_64 [ "aarch64-linux" ];

  environment = {
    systemPackages = with pkgs; [
      duperemove
    ];
    interactiveShellInit = ''
      firmwareupdate() {
        echo "Checking devices..."
        fwupdmgr get-devices
        echo "Refreshing metadata..."
        fwupdmgr refresh
        echo "Checking for updates..."
        fwupdmgr get-updates
        echo "Applying updates..."
        fwupdmgr update
      }
    '';
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
    config = {
      home-jdk.jdkPackages = [
        pkgs.jdk17
        pkgs.jdk21
        pkgs.jdk25
      ];
    };
  };

  home-manager.users.${userName}.home.stateVersion = "26.05";

  security.sudo = {
    enable = true;
  };

  services.tailscale.enable = true;

  nix.settings.auto-optimise-store = true;

  system.stateVersion = "26.05";

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

  time.timeZone = "Europe/Berlin";

  i18n.supportedLocales = options.i18n.supportedLocales.default ++ [
    "de_DE.UTF-8/UTF-8"
  ];

  foundrix = {
    general.keymap = "de-latin1";
  };
}