# Hardware:
# Mainboard: ASRock X870E Taichi
# CPU: AMD Ryzen 9 7950X @ 6.07 GHz (overclocked)
# RAM: 128 GB (2x64 GB) G.SKILL Tridenz Z5 NEO DDR5 6000 MHz
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
      nixosHardwareModules.common-cpu-adm-pstate
      nixosHardwareModules.common-gpu-amd
      ./filesystems.nix
    ];

  # Device configuration like name, platforms etc.
  device = {
    name = "my-pc";
    # Platforms this device supports. Usually, this only contains one value, but can be more.
    platforms = [ "x86_64" ];
    # If your setup is any more complex than a simple TTY, you'll find that cross-compilation breaks.
    # This is why it's disabled here in the template. If you want to build for architectures other than
    # your build platform, you have to set this to true. The alternative is to use binfmt emulation
    # and just pretend to be the host platform which works a lot better for many scenarios but is also slower.
    crossCompile = false;
  };

  boot.loader.timeout = 1;
}
