# Hardware:
# Mainboard: ASRock X870E Taichi
# CPU: AMD Ryzen 9 7950X @ 6.07 GHz (overclocked)
# RAM: 128 GB (2x64 GB) G.SKILL Trident Z5 NEO DDR5 6000 MHz
# GPU: PowerColor Red Devil AMD Radeon RX 7900XTX Limited Edition
# Storage:
#   Corsair MP700 2 TB NVMe
#   Crucial P3 Pro (CT4000P3PSSD8) 4 TB NVMe
#   4x SanDisk SSD Plus 1 TB SATA
# Mouse: Angry Miao Infinity 8k mouse
# Keyboard: Carolina Mech Fossil SE & Lemokey L5 HE 8k
# Headphones: beyerdynamic DT 770 Pro 80 Ohm
# Sound interface: TC Helicon GoXLR MINI
# Microphone: Shure SM7B
{
  inputs,
  foundrixModules,
  options,
  pkgs,
  pkgsUnstable,
  ...
}:
{
  imports =
    let
      nixosHardwareModules = inputs.nixos-hardware.nixosModules;
    in
    [
      nixosHardwareModules.common-cpu-amd
      nixosHardwareModules.common-cpu-amd-pstate
      nixosHardwareModules.common-gpu-amd
      nixosHardwareModules.common-pc
      nixosHardwareModules.common-pc-ssd
      foundrixModules.config.via
      foundrixModules.hardware.security.keystore.tpm2
      inputs.linux-nitrous.outPath
      ./filesystems.nix
    ];

  boot.loader.timeout = 5;

  device = {
    cpu.threads = 32;
    crossCompile = false;
    name = "triceratops";
    platforms = [ "x86_64" ];
  };

  environment = {
    systemPackages = with pkgs; [
      nodejs
      pkgsUnstable.openrgb-with-all-plugins
    ];
  };

  foundrix = {
    config.nix.buildDirOnTmp = true;
    general.keymap = "de-latin1";
  };

  hardware = {
    enableRedistributableFirmware = true;
    i2c.enable = true;
  };

  i18n.supportedLocales = options.i18n.supportedLocales.default ++ [
    "de_DE.UTF-8/UTF-8"
  ];

  linux-nitrous.processorFamily = "znver4";

  networking = {
    hostName = "triceratops";
    interfaces.enp11s0.wakeOnLan.enable = true;
  };

  services = {
    fwupd.enable = true;
    goxlr-utility.enable = true;
    openssh.enable = true;
    teamviewer.enable = true;
    # Use this to prevent teamviewerd from starting on system boot
    #systemd.services.teamviewerd.wantedBy = lib.mkForce [];
    #systemd.services.teamviewerd.serviceConfig.Restart = lib.mkForce "no";
    # Support for Carolina Mech Fossil and Lemokey L5 HE 8k
    udev.extraRules = ''
      KERNEL=="hidraw*", ATTRS{idVendor}=="4069", ATTRS{idProduct}=="0002", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
      KERNEL=="hidraw*", ATTRS{idVendor}=="362d", ATTRS{idProduct}=="0551", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
    '';
  };

  time.timeZone = "Europe/Berlin";
}