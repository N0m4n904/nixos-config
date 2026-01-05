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
  };
}
