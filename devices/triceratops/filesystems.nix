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

    "/home/noah/4TB-nvme" = {
      device = "/dev/disk/by-uuid/809a46eb-3234-4f56-9487-3e4887e47ba4";
      fsType = "btrfs";
      options = [
        "rw"
        "noatime"
        "compress=zstd:4"
      ];
    };

    "/home/noah/CCache" = {
      device = "/dev/disk/by-uuid/539e9a37-f705-42f8-878f-9f1360cffdc3";
      fsType = "btrfs";
      options = [
        "rw"
        "noatime"
        "compress=zstd:4"
      ];
    };

    "/home/noah/Development" = {
      device = "/dev/disk/by-uuid/6febead5-1f71-47f6-95e6-d2abb5c7523c";
      fsType = "btrfs";
      options = [
        "rw"
        "noatime"
        "compress=zstd:4"
      ];
    };

    "/home/noah/XOS" = {
      device = "/dev/disk/by-uuid/46600c98-15fc-4620-b017-7768ac3e9d3d";
      fsType = "btrfs";
      options = [
        "rw"
        "noatime"
        "compress=zstd:4"
      ];
    };

    "/home/noah/Stuff" = {
      device = "/dev/disk/by-uuid/9ea148e8-067a-4fd4-ace5-a90e89db91a9";
      fsType = "btrfs";
      options = [
        "rw"
        "noatime"
        "compress=zstd:4"
      ];
    };

    "/home/noah/SteamLibrary" = {
      device = "/dev/disk/by-uuid/1c15f678-66bf-4101-bd9e-f797fc7276d6";
      fsType = "btrfs";
      options = [
        "rw"
        "noatime"
        "compress=zstd:4"
      ];
    };

    "/home/noah/Stuff2" = {
      device = "/dev/disk/by-uuid/7efc90fd-0358-4807-ab9e-32117c34069f";
      fsType = "btrfs";
      options = [
        "rw"
        "noatime"
        "compress=zstd:4"
      ];
    };
  };
}
