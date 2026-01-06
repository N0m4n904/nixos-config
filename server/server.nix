{
  foundrixModules,
  ...
}:
{
  imports = [
    foundrixModules.profiles.server-baseline
    foundrixModules.config.virtualisation.docker
  ];

  users.allowNoPasswordLogin = true;
  services.getty.autologinUser = "noah";

  nix.settings.trusted-users = [ "root" "@wheel" ];

  boot.initrd.systemd.enable = true;
}