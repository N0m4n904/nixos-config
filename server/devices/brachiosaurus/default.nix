# Hardware:
# Mainboard: MSI X470 GAMING PLUS
# CPU: AMD Ryzen 7 3700X @ 4.43 GHz
# RAM: 16 GB (2x8 GB) Corsair Vengeance RGB PRO DDR4 3200 MHz
# GPU: MSI GeForce RTX 2080 DUKE 8G OC
# Storage:
#   Samsung SSD 970 PRO 512 GB NVMe
#   Crucial P3 Pro (CT4000P3PSSD8) 2 TB NVMe
#   Samsung SSD 850 PRO 256 GB SATA
{
  inputs,
  foundrixModules,
  pkgs,
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
      nixosHardwareModules.common-pc
      nixosHardwareModules.common-pc-ssd
      foundrixModules.config.filesystem.nix-tmp
      foundrixModules.hardware.security.keystore.tpm2
      ./filesystems.nix
      ../../../modules/hardware/gpu/nvidia.nix
    ];

  boot = {
    kernelPackages = pkgs.linuxPackages_6_18;
    loader.timeout = 1;
  };

  device = {
    cpu.threads = 16;
    crossCompile = false;
    name = "brachiosaurus";
    platforms = [ "x86_64" ];
  };

  environment = {
    systemPackages = with pkgs; [
      nodejs
    ];
  };

  foundrix = {
    config = {
      nix.buildDirOnTmp = true;
      shell.zsh.power10k = {
        colors = {
          dirAnchorBackground = "#9CA62C";
          dirAnchorForeground = "#0f0f0f";
          dirBackground = "#B8C639";
          dirForeground = "#0f0f0f";
          hostBackground = "#76A834";
          hostForeground = "#0f0f0f";
          osIconBackground = "#76B834";
          osIconForeground = "#0f0f0f";
          userBackground = "#5D872A";
          userForeground = "#0f0f0f";
        };
      };
    };
  };

  hardware = {
    enableRedistributableFirmware = true;
    i2c.enable = true;
  };

  networking = {
    hostName = "brachiosaurus";
    interfaces.enp34s0.wakeOnLan.enable = true;
    firewall.allowedUDPPorts = [ 9 ];
  };

  services = {
    fwupd.enable = true;
    openssh.enable = true;
  };
}