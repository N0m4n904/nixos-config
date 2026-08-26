# The programs that belong in the Steam library without coming from Steam.
#
# Kept apart from the mechanism in steam-shortcuts.nix, which knows how to write
# Steam's shortcuts file and nothing about what should be in it, and apart from
# either machine's configuration, because the answer is the same on both: an
# emulator and a launcher are wanted wherever there is a Steam library, and
# declaring them twice would let the two drift.
#
# Adding one means adding it here, not to a host.
{
  pkgs,
  pkgsUnstable,
  ...
}:

{
  imports = [
    ./steam-shortcuts.nix
  ];

  steamShortcuts = {
    # Named rather than derived, because configuration.nix names it the same way
    # - a let binding, not an option there is anything to read back.
    user = "noah";

    entries = {
      "Dolphin Emulator" = {
        package = pkgsUnstable.dolphin-emu;
        icon = "${pkgsUnstable.dolphin-emu}/share/icons/hicolor/256x256/apps/dolphin-emu.png";
        tags = [ "Emulator" ];
      };

      "NoRisk Client" = {
        package = pkgs.noriskclient-launcher;
        tags = [ "Launcher" ];
      };
    };
  };

  # Emulators ship udev rules for the controllers they talk to directly, which
  # have to be present system-wide rather than in the user's package set. It
  # travels with the shortcut for the same reason the shortcut is here: the rule
  # is useless without the program and the program is awkward without the rule.
  services.udev.packages = [ pkgsUnstable.dolphin-emu ];
}
