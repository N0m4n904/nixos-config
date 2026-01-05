{ config, ... }:
{
  foundrix.nixpkgs.allowedUnfreePackageNames = [
    "nvidia-x11"
    "nvidia-settings"
    "nvidia-persistenced"
  ];

  services.xserver.videoDrivers = ["nvidia"];

  hardware = {
    graphics.enable = true;
    nvidia = {
      modesetting.enable = true;
      open = true;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };
}