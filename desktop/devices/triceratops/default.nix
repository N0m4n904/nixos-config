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
  applyHomeManagerShared,
  inputs,
  foundrixModules,
  lib,
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
      foundrixModules.config.filesystem.nix-tmp
      foundrixModules.hardware.security.keystore.tpm2
      foundrixModules.config.gamescope-session
      ./filesystems.nix
      ../../../modules/hardware/hid/via.nix
      inputs.ammaster-bridge.nixosModules.default
      ../../../modules/teamviewer.nix
    ];

  boot.loader.timeout = 1;

  device = {
    cpu.threads = 32;
    crossCompile = false;
    name = "triceratops";
    platforms = [ "x86_64" ];
  };

  nix.settings.max-jobs = 8;

  environment = {
    systemPackages = with pkgs; [
      # Normally pulled in as a side effect of the XDG autostart entry, which is
      # turned off below; goxlr-client and friends should stay on PATH regardless.
      goxlr-utility
      nodejs
      pkgsUnstable.openrgb-with-all-plugins
    ];
  };

  foundrix = {
    config = {
      gamescope-session = {
        enable = true;
        hdr.enable = true;
        refreshRate = 175;
      };
      nix.buildDirOnTmp = true;
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
    nixpkgs.allowedUnfreePackageNames = [
      "steam"
      "steam-original"
      "steam-run"
      "steam-unwrapped"
    ];
  };

  hardware = {
    enableRedistributableFirmware = true;
    i2c.enable = true;
  };

  networking = {
    hostName = "triceratops";
  };

  # The GoXLR's lighting and its routing sinks - Game, Chat, Music, System, Sample -
  # only exist while this daemon runs, so when it does not start the device sits dark
  # and most of its outputs are missing from PipeWire.
  #
  # It ships as an XDG autostart entry, which failed twice over here: entries are
  # keyed by filename and a user-level one shadows the system one, and the user-level
  # one had been written by hand against a store path that was later collected. The
  # generator then found a missing executable and produced no unit at all, so the
  # correct system entry never got a look in. A user service is addressed by name
  # rather than filename and always carries the current store path.
  home-manager = applyHomeManagerShared {
    systemd.user.services.goxlr-daemon = {
      Unit = {
        Description = "GoXLR Utility daemon";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = lib.getExe' pkgs.goxlr-utility "goxlr-daemon";
        Restart = "on-failure";
        RestartSec = 2;
      };
      # Wanted by the generic graphical target, not the Hyprland one: the GoXLR should
      # work in whichever session is running.
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };

  services = {
    ammaster.enable = true;
    fwupd.enable = true;

    goxlr-utility = {
      enable = true;
      # Superseded by the user service above.
      autoStart.xdg = false;
    };

    openssh.enable = true;
    # Support for Carolina Mech Fossil, Lemokey L5 HE 8k, Keychron Link and Keychron K3 HE
    udev.extraRules = ''
      KERNEL=="hidraw*", ATTRS{idVendor}=="4069", ATTRS{idProduct}=="0002", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
      KERNEL=="hidraw*", ATTRS{idVendor}=="362d", ATTRS{idProduct}=="0551", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
      KERNEL=="hidraw*", ATTRS{idVendor}=="3434", ATTRS{idProduct}=="d030", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
      KERNEL=="hidraw*", ATTRS{idVendor}=="3434", ATTRS{idProduct}=="0e31", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
    '';
  };
}
