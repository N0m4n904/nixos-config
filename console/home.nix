# User packages for the console. The counterpart to desktop/home.nix, and much
# shorter by design: games, the launchers and emulators that run them, and the
# handful of tools desktop mode needs to be worth falling back to.
#
# The general toolkit in the repository root is not composed into this
# configuration, so anything genuinely needed here has to be named here.
{
  applyHomeManagerShared,
  pkgs,
  pkgsUnstable,
  ...
}:

{
  home-manager = applyHomeManagerShared {
    home.packages = with pkgs; [
      mangohud

      # dolphin-emu and noriskclient-launcher are absent on purpose. They are
      # declared as Steam shortcuts in console.nix, which installs them
      # system-wide so the shortcut can point at a path that survives an update.

      # Desktop mode is the repair bench: when a game will not start, these are
      # what tell you whether the GPU, the sensors or the filesystem is at fault.
      # Small enough that leaving them out would be a false economy.
      file
      lm_sensors
      p7zip
      pciutils
      unzip
      vim
      vulkan-tools
      wl-clipboard
    ];
  };
}
