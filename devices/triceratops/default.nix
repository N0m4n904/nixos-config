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
  hardware,
  ...
}:
{
  imports =
    let
      nixosHardwareModules = inputs.nixos-hardware.nixosModules;
    in
    [
      nixosHardwareModules.common-pc
      nixosHardwareModules.common-pc-ssd
      nixosHardwareModules.common-cpu-amd
      nixosHardwareModules.common-cpu-amd-pstate
      nixosHardwareModules.common-gpu-amd
      foundrixModules.config.via
      foundrixModules.hardware.security.keystore.tpm2
      inputs.linux-nitrous.outPath
      ./filesystems.nix
    ];

  device = {
    name = "triceratops";
    cpu.threads = 32;
    platforms = [ "x86_64" ];
    crossCompile = false;
  };

  foundrix.config.nix.buildDirOnTmp = true;

  environment = {
    systemPackages = with pkgs; [
      nodejs
      pkgsUnstable.openrgb-with-all-plugins
    ];
  };

  linux-nitrous.processorFamily = "znver4";

  foundrix = {
    general.keymap = "de-latin1";
  };

  networking = {
    hostName = "triceratops";
    interfaces.enp11s0.wakeOnLan.enable = true;
  };

  time.timeZone = "Europe/Berlin";

  i18n.supportedLocales = options.i18n.supportedLocales.default ++ [
    "de_DE.UTF-8/UTF-8"
  ];

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

  hardware.i2c.enable = true;

  boot.loader.timeout = 5;

  hardware.enableRedistributableFirmware = true;
}
