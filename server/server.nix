{
  foundrixModules,
  config,
  ...
}:
{
  imports = [
    foundrixModules.profiles.server-baseline
  ];

  users.allowNoPasswordLogin = true;
  services.getty.autologinUser = "noah";

  nix.settings.trusted-users = [ "root" "@wheel" ];
}