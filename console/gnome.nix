# GNOME for the console's desktop mode, deliberately not the one the
# workstations run.
#
# Two reasons for a separate module rather than importing
# desktop/desktop-environments/gnome. Its dconf pins a dash of favourites -
# VSCodium, IntelliJ, Spotify, Signal - that this machine does not install, so
# every one of them would be a broken launcher. And its extension set exists to
# make a desktop pleasant to live in, which is not what this is: desktop mode
# here is somewhere you pass through to fix something or install a game.
#
# GDM rather than the COSMIC greeter because autologin has to work. Without it
# the console stops at a password prompt and never reaches the autostart that
# hands over to game mode.
{
  applyHomeManagerShared,
  foundrixModules,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    foundrixModules.components.desktop-environments.gnome
    foundrixModules.config.graphics.gtk-dark
    foundrixModules.config.graphics.themes.adwaita-dark
  ];

  foundrix.components.desktop-environments.gnome = {
    useGdm = true;

    # One extension, and only because GNOME draws no desktop icons without it -
    # which would leave the Game Mode entry sitting in ~/Desktop where nothing
    # ever shows it. The rest of the workstation's set is for a desktop somebody
    # lives in; this one is a waypoint.
    extensions = [ pkgs.gnomeExtensions.desktop-icons-ng-ding ];
  };

  # The first-run wizard has nothing to ask a console. Worse, it holds the
  # session while it waits for answers nobody is there to give, so the handover
  # to game mode arrives on top of a half-built desktop.
  services.gnome.gnome-initial-setup.enable = false;

  home-manager = applyHomeManagerShared {
    dconf.settings = {
      "org/gnome/desktop/interface".color-scheme = "prefer-dark";

      # Game Mode first, then the browser and the file manager - the browser
      # because a console still needs captive portals and downloads, the file
      # manager because the alternative is a terminal.
      "org/gnome/shell".favorite-apps = lib.mkForce [
        "gamescope-session.desktop"
        "steam.desktop"
        "zen-beta.desktop"
        "org.gnome.Nautilus.desktop"
      ];

      # Nothing should blank or lock a machine whose desktop is a waypoint, and
      # which is usually being looked at from a sofa when it is on screen at all.
      "org/gnome/desktop/session".idle-delay = lib.gvariant.mkUint32 0;
      "org/gnome/desktop/screensaver".lock-enabled = false;

      # Nor should it suspend itself. GNOME's default is to suspend on mains
      # after twenty minutes, which is a laptop's idea of idle applied to a
      # machine whose whole job is to sit still - downloading an update, running
      # a shader cache build, or waiting on a game that is not driving input.
      #
      # Both kinds, though this hardware only has the one: a console should
      # never decide on its own to go to sleep. Explicit sleep, from Steam's
      # power menu or GNOME's, is untouched.
      "org/gnome/settings-daemon/plugins/power" = {
        sleep-inactive-ac-type = "nothing";
        sleep-inactive-battery-type = "nothing";
      };
    };
  };
}
