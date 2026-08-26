# Hardware:
# CPU: AMD Ryzen 5 2600 (Zen+, 6 cores / 12 threads)
# RAM: 32 GB
# GPU: NVIDIA GeForce GTX 970 (Maxwell, GM204)
# Storage: Samsung SSD 980 1 TB NVMe
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}@args:
{
  imports =
    let
      nixosHardwareModules = inputs.nixos-hardware.nixosModules;

      # The flasher and the updater are built from this same device
      # configuration, and get targetConfig passed in where a full system does
      # not. They have no gamescope session to tune.
      isInstallMedium = args ? targetConfig;
    in
    [
      nixosHardwareModules.common-cpu-amd
      nixosHardwareModules.common-pc
      nixosHardwareModules.common-pc-ssd
      # common-cpu-amd-pstate is deliberately absent, unlike on the other AMD
      # hosts here. amd_pstate needs CPPC, which arrived with Zen 2; on this
      # Zen+ chip the driver would not bind and the kernel would fall back to
      # acpi-cpufreq regardless, so the kernel parameter would only be noise.
      ../../../modules/hardware/gpu/nvidia.nix
      ../../../modules/gaming/console-image.nix
    ]
    ++ lib.optional (!isInstallMedium) ./gamescope.nix;

  # No filesystems.nix, unlike the desktop and server devices: console-image.nix
  # defines the whole layout, down to which partition /var is created on at first
  # boot. Declaring mounts here would collide with it.

  # The desktop profile asks for the newest kernel, which this card cannot
  # follow. Linux 7.2 finished removing strncpy, and NVIDIA 580 - the last
  # branch that supports Maxwell at all - still calls it, so its module fails to
  # compile there. 6.18 is the newest that builds it, and is late enough to
  # still carry ntsync, which the gamescope session wants.
  #
  # This pin comes off the day the card does.
  boot.kernelPackages = pkgs.linuxPackages_6_18;

  hardware.nvidia = {
    # Both of these invert the shared module's defaults, because this card is
    # old enough to have fallen off both of NVIDIA's current tracks.
    #
    # The open kernel modules begin at Turing; this is Maxwell. nixos-hardware
    # reaches the same conclusion in its own maxwell profile.
    open = false;

    # 595 has dropped Maxwell entirely. 580 is the last branch that carries it,
    # kept as an LTS branch until August 2028. It dictates the kernel pinned
    # above; check the two together whenever either moves.
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
  };

  # Set through the image module rather than boot.loader.timeout directly, which
  # it owns: an image writes the loader config into the ESP at build time, so
  # the two would conflict.
  #
  # mkDefault because this device configuration is reused to build the updater,
  # whose recipe asks for a timeout of zero - it boots straight into its one job
  # and has no menu worth pausing on. Stated at normal priority the two collide
  # and the updater cannot be evaluated at all.
  foundrix.config.image.boot.systemd-boot.timeout = lib.mkDefault 1;

  device = {
    cpu.threads = 12;
    crossCompile = false;
    name = "stegosaurus";
    platforms = [ "x86_64" ];
  };

  networking.hostName = "stegosaurus";

  gameConsole.image = {
    # The only NVMe in the machine, so the name is settled by there being
    # nothing to race with. On a host with a second drive this would want
    # /dev/disk/by-id/nvme-Samsung_SSD_980_1TB_<serial> instead - `ls -l
    # /dev/disk/by-id` on the machine gives the exact name.
    dataDevice = "/dev/nvme0n1";

    # A guess until the first build measures the closure, and deliberately a
    # loose one: two slots at this size are 4% of a 1 TB disk, while guessing
    # short fails the image build after everything else has already been built.
    # The installer barely notices either way - the unused half of a slot is
    # zeroes, and compresses to almost nothing.
    slotSize = "20G";

    # Bump on every image this console is meant to accept as an update.
    #   2: GPU access by group rather than by logind's session ACLs, and the
    #      initrd repart ordering foundrix drops restored.
    #   3: variable refresh rate and the MangoHud overlay turned off, neither of
    #      which this card can do anything useful with.
    #   4: the four fixes that make sysupdate work unaided, and group membership
    #      for the network and for controllers.
    #   5: game mode entered from a desktop session rather than started cold at
    #      boot, so it inherits a real login the way it does on a workstation.
    #   6: CAP_SYS_NICE dropped, which was stopping Steam's sandbox from
    #      starting at all; composition forced; GNOME instead of COSMIC with its
    #      first-run wizard off; and Steam's update button wired to sysupdate.
    #   7: the gamescope binary put back where the session looks for it, a
    #      watchdog that returns to the desktop when it never appears, and every
    #      dconf setting reaching dconf for the first time.
    #   8: the polkit grant that lets the user reach game mode once the display
    #      manager it was launched from is gone, and the watchdog above taught
    #      to recognise a running compositor.
    #   9: the first-run wizard's firmware gate answered with the code that
    #      means "nothing pending" rather than the one that means "apply an
    #      update I cannot apply"; Steam's update button reachable at the
    #      absolute path it actually calls; and the console kept awake for the
    #      length of a transfer.
    #  10: the first-run wizard given a dummy updater rather than an answer it
    #      will not accept - the same flag the SteamOS clones use, since the
    #      client re-derives the outcome from its own bookkeeping and no exit
    #      code can satisfy it. Firmware gate back to "nothing pending".
    #  11: five seconds of deliberate idling dropped from the session start, and
    #      the kernel no longer writing to a television - nixpkgs was appending
    #      its own loglevel after foundrix's and quietly winning.
    #  12: immediate flips off. The screen going black while the connector
    #      stayed powered and gamescope kept compositing was a frame never
    #      reaching the display, not a display switching itself off.
    #  13: firmware, which this device never had - so neither its wifi nor its
    #      bluetooth could work. Card-specific compositor tuning moved out of
    #      the shared console configuration and into this device.
    #  14: the compositor's own output sent to the journal rather than to the
    #      television, which both stops it scrolling past on every launch and
    #      makes it readable after the fact - `journalctl -t gamescope`.
    #  15: forced composition removed. It disabled direct scan-out on a driver
    #      where that path produces black and corrupted frames, and the fault it
    #      was added for had a different cause. Steam's Big Picture renders
    #      correctly on this card outside gamescope, so the card is not at fault.
    version = "15";
  };
}
