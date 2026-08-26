# Makes the console's dconf settings actually reach dconf.
#
# home-manager-prebuilt bakes each home into the image and disables the
# activation service that would normally realise a generation - see
# console-home.nix for why. That is fine for anything home-manager expresses as
# a file, which is most of it, and wrong for the one part it does not: dconf is
# a binary database, written imperatively by `dconf load` during activation. No
# activation, no writes. Every dconf.settings on this console - the GNOME
# favourites, the dark theme, the idle timeout, and which shell extensions are
# switched on - has therefore been declared and then silently discarded.
#
# The settings are not wrong, only unread, so they are mirrored into the system
# database instead of being restated. That suits an appliance better anyway:
# system settings are defaults rather than assertions, so anything changed in
# GNOME still lands in the user database and still wins, and none of it depends
# on a writable store.
#
# Single-user by construction: /etc/dconf/profile/user is one database for
# whoever logs in, so there is one console account to read from and no sensible
# way to merge two.
{
  config,
  lib,
  ...
}:

let
  cfg = config.gameConsole;

  # nixpkgs' generator refuses a bare integer, because GSettings has six integer
  # types and guessing the width writes a value the schema rejects. home-manager
  # is laxer and reads them as int32, which is what the settings arriving here
  # actually are - cursor-size and the like. Stating that assumption once beats
  # annotating every upstream module that writes a plain number.
  asGVariant = value: if builtins.isInt value then lib.gvariant.mkInt32 value else value;
in
{
  config = lib.mkIf cfg.enable {
    programs.dconf.profiles.user.databases = [
      {
        settings = lib.mapAttrs (
          _: lib.mapAttrs (_: asGVariant)
        ) config.home-manager.users.${cfg.user}.dconf.settings;
      }
    ];
  };
}
