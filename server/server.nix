{
  foundrixModules,
  ...
}:
{
  imports = [
    foundrixModules.profiles.server-baseline
  ];

  users.allowNoPasswordLogin = true;
  services.getty.autologinUser = "noah";
}