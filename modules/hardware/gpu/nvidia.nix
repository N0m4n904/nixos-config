{ config, lib, ... }:
{
  foundrix.nixpkgs.allowedUnfreePackageNames = [
    "nvidia-x11"
    "nvidia-settings"
    "nvidia-persistenced"
    # Only reached when open = false: the open kernel modules are free, the
    # closed ones are a separate package with a licence to accept.
    "nvidia-kernel-modules"
  ];

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware = {
    graphics.enable = true;
    nvidia = {
      modesetting.enable = true;
      nvidiaSettings = true;

      # Defaults, because both depend on how old the card is and only the device
      # knows that. They suit Turing and later: the open kernel modules start
      # there, and NVIDIA's current branch has dropped everything older. A
      # Maxwell or Pascal card has to override both.
      open = lib.mkDefault true;
      package = lib.mkDefault config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };
}
