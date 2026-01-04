{ ... }:
{
  services.teamviewer.enable = true;
  # Use this to prevent teamviewerd from starting on system boot
  #systemd.services.teamviewerd.wantedBy = lib.mkForce [];
  #systemd.services.teamviewerd.serviceConfig.Restart = lib.mkForce "no";

  foundrix = {
    nixpkgs.allowedUnfreePackageNames = [
      "teamviewer"
    ];
  };
}