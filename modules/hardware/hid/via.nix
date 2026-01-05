{ pkgs, applyHomeManagerShared, ... }:
{
  hardware.keyboard.qmk.enable = true;
  services.udev.packages = [ pkgs.via ];

  foundrix.nixpkgs.allowedUnfreePackageNames = [
    "via"
  ];

  home-manager = applyHomeManagerShared  {
    home.packages = with pkgs; [
      via
    ];
  };
}