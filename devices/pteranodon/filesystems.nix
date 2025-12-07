{
  boot.initrd.luks = {
    devices."main" = {
      device = "/dev/disk/by-partlabel/root";
    };
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

    "/home/noah/ccache" = {
      device = "/dev/disk/by-uuid/a511957e-372d-426a-9f9f-efa9e2140ca5";
      fsType = "btrfs";
      options = [
        "rw"
        "noatime"
        "compress=zstd:4"
      ];
    };
  };
  boot.supportedFilesystems = [ "btrfs" ];
}
