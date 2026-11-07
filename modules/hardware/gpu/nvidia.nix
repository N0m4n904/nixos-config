{ config, lib, ... }:
let
  nvidiaPackages = config.boot.kernelPackages.nvidiaPackages;

  # Linux 7.2 finished removing strncpy, and 595.71.05 - what nixpkgs 26.05
  # carries as NVIDIA's current branch - still calls it in os-interface.c, so its
  # kernel modules no longer compile. 595.112.07, the release nixos-unstable
  # ships as production, calls strscpy there instead. NixOS/nixpkgs#554125.
  #
  # Stated as a version and hashes rather than taken from the unstable package
  # set, because a kernel module only loads into the exact kernel it was built
  # against, and that kernel comes from the pinned nixpkgs.
  strscpyRelease = nvidiaPackages.mkDriver {
    version = "595.112.07";
    sha256_64bit = "sha256-Gjjs1Tii2mIypzMBhAY69Z6fyUbJCMylVb0HkJhIufA=";
    sha256_aarch64 = "sha256-7qQuOKX9xS/wpKa+bEOqsS2euJjJu182vl+6UU6bxR0=";
    openSha256 = "sha256-nQnXGCcvo4i7eGaVft3Xc9dRUPPH0v9Zi87cfI4i/Ys=";
    settingsSha256 = "sha256-2bWSou/9J3EojhSRXBol/+yGGu2XZ6EuCptb5qXHM14=";
    persistencedSha256 = "sha256-cGMEUXN7WPu822zZDLTSu6Owj8VXG4PNmhe9oKqMMKI=";
  };

  # A floor rather than a pin, so nixpkgs takes over again the moment it carries
  # something newer and this whole binding can be deleted without thinking about
  # which of the two is ahead.
  currentBranch =
    if lib.versionAtLeast nvidiaPackages.stable.version strscpyRelease.version then
      nvidiaPackages.stable
    else
      strscpyRelease;
in
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
      package = lib.mkDefault currentBranch;
    };
  };
}
