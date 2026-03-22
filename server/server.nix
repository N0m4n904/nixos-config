{
  foundrixModules,
  ...
}:
{
  imports = [
    foundrixModules.profiles.server-baseline
    foundrixModules.config.virtualisation.docker
  ];

  nix.settings.trusted-users = [ "root" "@wheel" ];

  boot.initrd.systemd.enable = true;
}