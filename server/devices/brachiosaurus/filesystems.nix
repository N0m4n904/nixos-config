{
  boot.initrd.luks = {
    devices."main" = {
      device = "/dev/disk/by-partlabel/root";
    };
  };

  boot.supportedFilesystems = {
    btrfs = true;
  };

  fileSystems = {
    "/" = {
      device = "/dev/mapper/main";
      fsType = "btrfs";
      options = [
        "compress=no"
        "noatime"
      ];
    };

    "/boot" = {
      device = "/dev/disk/by-label/ESP";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };

    "/home" = {
      device = "/dev/mapper/main";
      fsType = "btrfs";
      options = [
        "subvol=@home"
        "compress=lzo"
        "noatime"
      ];
    };

    "/home/noah/XOS" = {
      device = "/dev/disk/by-uuid/4dc1680c-da77-4515-b464-1e2c56d0a7a4";
      fsType = "btrfs";
      options = [
        "rw"
        "noatime"
        "compress=zstd:4"
      ];
    };

    "/home/noah/CCache" = {
      device = "/dev/disk/by-uuid/c76cdb0a-7e73-47e6-b1fa-5e85c02435aa";
      fsType = "btrfs";
      options = [
        "rw"
        "noatime"
        "compress=zstd:4"
      ];
    };
  };
}
