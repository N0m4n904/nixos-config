# The console's OS configuration: the desktop stack reduced to what a games
# machine needs, plus the two modules that make it boot into game mode and run
# from a read-only store.
#
# The rule applied throughout is that a package earns its place by serving a
# game, a controller, or the desktop mode you fall back to when something needs
# fixing. Editors, IDEs, office and productivity tooling are not here - not only
# because the console has no use for them, but because every gigabyte lands in
# two store slots and again in the flasher that carries them.
{
  foundrixModules,
  inputs,
  options,
  pkgs,
  pkgsUnstable,
  ...
}:

let
  steamMandatoryUpdate = pkgs.callPackage ../modules/gaming/steamos-mandatory-update.nix { };
in
{
  imports = [
    foundrixModules.profiles.desktop-full
    foundrixModules.config.graphics.cursors.breezex-rosepine
    foundrixModules.config.graphics.gtk-dark
    foundrixModules.config.graphics.qt
    foundrixModules.hardware.peripherals.nsw2-controller
    foundrixModules.components.steam
    ../modules/gaming/game-console.nix
    ../modules/gaming/console-ota.nix
    ../modules/gaming/game-mode-desktop-entry.nix
    ../modules/gaming/proton-cachyos.nix
    ../modules/gaming/console-home.nix
    ../modules/browser/zen.nix
    ../modules/overlays/noriskclient-launcher.nix
    inputs.joycon-colors.nixosModules.default
    ./home.nix
  ];

  gameConsole = {
    enable = true;
    user = "noah";

    # Which machine publishes updates - a property of this installation rather
    # than of the console module, which is why it carries no default there. The
    # name resolves over the tailnet, so it survives the console moving or the
    # router handing out a different lease; triceratops has to allow the port on
    # its tailscale0 interface, which desktop/devices/triceratops does.
    updateServer = "http://triceratops:8000/";

    # Published into Steam so they are reachable from game mode with a
    # controller, rather than only from desktop mode. Declaring them here also
    # installs them; see modules/gaming/steam-shortcuts.nix for why that has to
    # be system-wide.
    steamShortcuts = {
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
  # have to be present system-wide rather than in the user's package set.
  services.udev.packages = [ pkgsUnstable.dolphin-emu ];

  # gamescope is normally launched through a wrapper carrying CAP_SYS_NICE, so it
  # can ask for realtime scheduling. Steam's container runtime inherits that,
  # and bubblewrap refuses to run holding capabilities it did not expect -
  # "Unexpected capabilities but not setuid". Steam then exits immediately and
  # gamescope is left composing an empty screen, which looks like a display
  # fault rather than a launcher that never started.
  #
  # The realtime scheduling is worth less than Steam running.
  programs.gamescope.capSysNice = false;

  foundrix.config.gamescope-session = {
    # Nothing to schedule in realtime once the capability above is gone, and
    # passing --rt without it only produces a warning.
    realtimeScheduling = false;

    # Everything this session needs that depends on which graphics card is
    # fitted - forced composition, no adaptive sync, no immediate flips, no
    # overlay - lives with the device instead, in
    # console/devices/<name>/gamescope.nix. None of it generalises, and a
    # console built on newer hardware wants all of it left alone.

    # foundrix's own defaults, plus the flag that gets the first-run wizard past
    # its update step.
    #
    # Read from the option rather than written out again, because -steamos3 and
    # the rest are foundrix's decision and should stay its decision: restating
    # them here would pin a copy that quietly stops tracking upstream. Defining
    # this option at all discards the default, and a list cannot be appended to
    # with mkAfter, so the default is taken from the declaration and extended.
    #
    # -steamos3 makes Steam believe it is a Deck, and the wizard then insists on
    # applying an OS update before it will show a login screen. There is no exit
    # code that satisfies it: the client discards the helper's status and
    # re-derives the outcome from its own per-component bookkeeping, so a helper
    # that returns success without changing any version is still recorded as
    # failure 2. The wizard skips the step only when the client reports
    # supports_os_updates as false, which is a protobuf field the client fills in
    # itself and nothing here can set.
    #
    # -testoobeupdater replaces the wizard's updater with a dummy one that
    # succeeds, which is how Bazzite solves the same problem. It is a client flag
    # rather than anything SteamOS-specific, and it is present in this client -
    # linux64/steamclient.so carries both it and -testlongoobeupdater.
    #
    # Scoped to the wizard by its own definition, so it has no bearing on the OS
    # updates offered later through Steam's settings; those go to
    # modules/gaming/steamos-update.nix and on to systemd-sysupdate.
    steamArgs = options.foundrix.config.gamescope-session.steamArgs.default ++ [
      "-testoobeupdater"
    ];
  };

  # Proton-CachyOS comes from ../modules/gaming/proton-cachyos.nix, which appends
  # itself to this list.
  programs.steam = {
    protontricks.enable = true;
    extraCompatPackages = [ pkgsUnstable.proton-ge-bin ];

    # Lands in the Steam runtime's /usr/bin, which is where Steam looks for it -
    # the same route foundrix uses to give Steam steamos-session-select.
    extraPackages = [
      (pkgs.callPackage ../modules/gaming/steamos-update.nix { })
      steamMandatoryUpdate
    ];
  };

  # Not only in Steam's FHS, unlike everything else it calls: the first-run
  # wizard runs this one against the host's PATH rather than the container's.
  environment.systemPackages = [ steamMandatoryUpdate ];

  foundrix = {
    hardware.peripherals.nsw2-controller.enable = true;
    nixpkgs.allowedUnfreePackageNames = [
      "steam"
      "steam-original"
      "steam-run"
      "steam-unwrapped"
    ];
  };

  hardware.joycon-color-change = {
    enable = true;
    gui = true;
  };

  environment.variables = {
    BROWSER = "zen-beta";
  };

  # A television should not be shown kernel logs. Switching into game mode
  # stops the display manager and leaves the bare console up for the second or
  # two it takes gamescope to claim the screen, and whatever the kernel last
  # printed is sitting there waiting to be read by nobody.
  #
  # foundrix already asks for loglevel=2, but nixpkgs appends its own
  # loglevel= from this option afterwards and the last one on the command line
  # wins, so the default of 4 quietly overrides it. Setting the option is
  # therefore the only way to make the request stick.
  #
  # 3 rather than 0: errors stop reaching the screen, while the levels that
  # mean the machine is in trouble - critical, alert, emergency - still do.
  boot = {
    consoleLogLevel = 3;

    # No blinking cursor on the empty console either, for the same handful of
    # seconds.
    kernelParams = [ "vt.global_cursor_default=0" ];
  };

  # An appliance is expected to work with whatever hardware it is built around,
  # and nothing about a console makes that hardware predictable - so the answer
  # for every console is the same "yes, install the blobs", which makes this a
  # property of the class rather than of any one machine.
  #
  # The desktop and server devices each set this individually, because they
  # inherit it from the hardware configuration nixos-generate-config writes. An
  # image-based device has no such file, so a console that did not state it here
  # would silently have no firmware at all - which is what happened to
  # stegosaurus, whose Intel 9260 reported "iwlwifi: no suitable firmware found"
  # and had neither wifi nor bluetooth until v13.
  #
  # One consequence worth knowing: this is the OS configuration, so it does not
  # reach the flasher, updater or ISO, which are built from the device alone. On
  # a console whose display needs firmware to come up at all - any AMD card -
  # install media may need it stated device-side too.
  hardware.enableRedistributableFirmware = true;

  # An appliance with a read-only store has no `nixos-rebuild` to fix itself
  # with, and a machine wired to a television is an awkward place to read a
  # journal from. This is how you get at it: over the LAN, or from anywhere
  # through the Tailscale that configuration.nix already turns on for every host.
  #
  # Host keys need no special handling despite the volatile root - the /var
  # persistence that comes with it already relocates them to /var/etc, so
  # reconnecting does not raise a changed-key warning after every reboot.
  services.openssh.enable = true;
}
