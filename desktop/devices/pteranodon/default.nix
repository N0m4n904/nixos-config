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
      foundrixModules.config.gamescope-session
      inputs.led-matrix-monitoring.nixosModules.led-matrix-monitoring
      ./filesystems.nix
      ./power-profiles
      ../../../modules/hardware/hid/via.nix
    ];

  boot = {
    loader.timeout = 1;
    kernel.sysctl = {
      "vm.page-cluster" = 0;
      "vm.swapiness" = 120;
    };
  };

  device = {
    cpu.threads = 16;
    crossCompile = false;
    name = "pteranodon";
    platforms = [ "x86_64" ];
  };

  nix.settings.max-jobs = 4;

  zramSwap = {
    enable = true;
    memoryPercent = 33;
  };

  foundrix = {
    config = {
      gamescope-session = {
        enable = true;
        refreshRate = 165;
        adaptiveSync = true;
      };
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
    nixpkgs.allowedUnfreePackageNames = [
      "steam"
      "steam-original"
      "steam-run"
      "steam-unwrapped"
    ];
  };

  hardware = {
    enableRedistributableFirmware = true;
  };

  networking = {
    hostName = "pteranodon";
  };

  services = {
    fwupd = {
      enable = true;
      extraRemotes = [ "lvfs-testing" ];
    };
    openssh.enable = true;
    # Support for Backlit Keyboard ISO, Numpad and LED Matrix modules
    udev.extraRules = ''
      KERNEL=="hidraw*", ATTRS{idVendor}=="32ac", ATTRS{idProduct}=="0014", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
      KERNEL=="hidraw*", ATTRS{idVendor}=="32ac", ATTRS{idProduct}=="0018", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
      SUBSYSTEM=="tty", ATTRS{idVendor}=="32ac", ATTRS{idProduct}=="0020", MODE="0666", GROUP="dialout"
      SUBSYSTEM=="usb", ATTRS{idVendor}=="32ac", ATTRS{idProduct}=="0020", MODE="0666", GROUP="dialout"
    '';
    led-matrix-monitoring = {
      enable = true;
      topLeft = "cpu";
      bottomLeft = "mem-bat";
      topRight = "temp";
      bottomRight = "fan";
      disableKeyListener = true;
      user = "noah";
    };
  };

  systemd.services.led-matrix-monitoring = {
    environment = {
      DISPLAY = ":0";
    };
    serviceConfig = {
      After = [ "graphical-session.target" ];
      Wants = [ "graphical-session.target" ];
    };
  };
}