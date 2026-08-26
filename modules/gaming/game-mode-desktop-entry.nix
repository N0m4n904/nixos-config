# Puts the Game Mode launcher on the desktop itself.
#
# foundrix's gamescope-session module already installs the entry into the
# application menu, which is enough to find it but not to reach for it: game
# mode is the one thing on these machines you want to start without a keyboard,
# from across a room. A copy on the desktop is that.
#
# Shared because it means opposite things on either side of the split, while
# being the same file. On a workstation it is the way in - a visit to Steam that
# ends by returning to the desktop. On the console it is the way back, since the
# machine boots into game mode and only ends up here when something needed
# fixing.
{
  applyHomeManagerShared,
  config,
  foundrixModules,
  ...
}:

{
  imports = [
    foundrixModules.config.gamescope-session
  ];

  home-manager = applyHomeManagerShared {
    # Executable, or the file is offered as text to read rather than something
    # to launch.
    home.file."Desktop/gamescope.desktop" = {
      source = "${config.foundrix.config.gamescope-session.desktopEntry}/share/applications/gamescope-session.desktop";
      executable = true;
    };
  };
}
