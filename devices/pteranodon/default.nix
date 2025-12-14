# Hardware:
# Framework 16 Laptop
# CPU: AMD Ryzen 9 7940HS @ 5.26 GHz
# RAM: 32 GB (2x16 GB) DDR5 5600 MHz
# GPU: AMD Radeon RX 7700S
# Storage:
#   WD_BLACK SN850X 2 TB NVMe
#   Phison ESMP512GBKB4C3-E13TS 512GB NVMe
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
      foundrixModules.config.filesystem.nix-tmp
      foundrixModules.hardware.security.keystore.tpm2
      foundrixModules.hardware.hosts.framework.laptop-16-7040
      ./filesystems.nix
      ../../modules/via.nix
    ];

  boot.loader.timeout = 1;

  device = {
    cpu.threads = 16;
    crossCompile = false;
    name = "pteranodon";
    platforms = [ "x86_64" ];
  };

  foundrix = {
    config = {
      nix.buildDirOnTmp = true;
      shell.zsh.power10k = {
        colors = {
          dirAnchorBackground = "#D0D0D2";
          dirAnchorForeground = "#F4ECEC";
          dirBackground = "#5A3A3C";
          dirForeground = "#F0E6E6";
          hostBackground = "#6E6E72";
          hostForeground = "#0F0F0F";
          osIconBackground = "#363636";
          osIconForeground = "#ffffff";
          userBackground = "#a3080f";
          userForeground = "#ffffff";
        };
      };
    };
    general.keymap = "de-latin1";
  };

  hardware = {
    enableRedistributableFirmware = true;
  };

  i18n.supportedLocales = options.i18n.supportedLocales.default ++ [
    "de_DE.UTF-8/UTF-8"
  ];

  networking = {
    hostName = "pteranodon";
  };

  services = {
    fwupd = {
      enable = true;
      extraRemotes = [ "lvfs-testing" ];
    };
    openssh.enable = true;
  };

  time.timeZone = "Europe/Berlin";
}