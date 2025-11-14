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
      inputs.linux-nitrous.outPath
      ./filesystems.nix
    ];

  boot.loader.timeout = 5;

  device = {
    cpu.threads = 16;
    crossCompile = false;
    name = "pteranodon";
    platforms = [ "x86_64" ];
  };

  foundrix = {
    config.nix.buildDirOnTmp = true;
    general.keymap = "de-latin1";
  };

  hardware = {
    enableRedistributableFirmware = true;
  };

  i18n.supportedLocales = options.i18n.supportedLocales.default ++ [
    "de_DE.UTF-8/UTF-8"
  ];

  linux-nitrous.processorFamily = "znver4";

  networking = {
    hostName = "pteranodon";
  };

  services = {
    fwupd.enable = true;
    openssh.enable = true;
  };

  time.timeZone = "Europe/Berlin";
}