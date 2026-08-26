# Appliance image for the console: a read-only, compressed nix store in one of
# two slots, updated by writing a whole new store into the idle slot and
# rebooting into it. Nothing the machine runs can alter the system it booted,
# and the previous slot stays intact as a rollback.
#
# Importing this module *is* the switch - unlike gameConsole.enable, it decides
# how the machine is partitioned and booted, so it cannot sit dormant behind a
# flag in a configuration shared with ordinary hosts. Import it from the console
# device and nowhere else.
#
# The system disk is laid out as ESP + two equally sized store slots; whatever
# is left of the data disk becomes /var, and on this machine that space is the
# game library. There is no writable store, so `nixos-rebuild switch` does not
# apply here - see the update paths at the bottom of this file.
#
# This belongs in the device configuration. Its counterpart, console-home.nix,
# belongs in the OS configuration and is not optional: a read-only store needs
# both halves.
{
  config,
  foundrixModules,
  lib,
  utils,
  ...
}@args:

let
  cfg = config.gameConsole.image;
  partitionIds = config.foundrix.config.image.partition-ids;

  # The flasher and the updater are built from this same device configuration,
  # and are handed the system they act on as targetConfig. Nothing else is, so
  # its presence is how a system built from here can tell it is the installation
  # medium rather than the console.
  isInstallMedium = args ? targetConfig;

  # Read back rather than used directly, because the flasher and updater raise
  # this figure to fit the compressed target image they carry. Following the
  # resolved option keeps both slots agreeing with each other in every system
  # built from here.
  slotSize = config.foundrix.config.image.store.erofs-readonly.sizeMin;

  # A stick that installs the console, or one that updates it, has no use for a
  # spare slot of its own - it never receives an update, it delivers one. Left
  # at the console's size it would silently double the medium, which is the
  # difference between an image that fits a USB drive and one that does not.
  emptySlotSize = if isInstallMedium then "1M" else slotSize;

  storePartition =
    if isInstallMedium then
      {
        # Sized to what it actually holds rather than to the console's slot.
        # foundrix sizes an install medium's store from the sum of the target's
        # partitions, which counts the empty half of the A/B layout and the
        # slack in the full half - so most of the resulting image is nothing at
        # all. Minimize is cheap here: erofs is read-only, so repart can measure
        # it without building it twice.
        Minimize = "best";

        # The A/B layout appends the image version to this label, and the
        # flasher recipe mounts /nix/store from the unversioned name. Left
        # alone, the two disagree and the medium cannot find its own store at
        # boot.
        Label = lib.mkForce "store";
      }
    else
      {
        Minimize = "off";
        SizeMaxBytes = slotSize;
      };
in
{
  imports = [
    foundrixModules.profiles.image.readonly-ab
    foundrixModules.config.runtime.repart.data
    foundrixModules.config.filesystem.root-tmpfs
    foundrixModules.config.filesystem.var
  ];

  options.gameConsole.image = {
    dataDevice = lib.mkOption {
      type = lib.types.str;
      example = "/dev/disk/by-id/nvme-eui.0025380a1b2c3d4e";
      description = ''
        Disk the runtime partitions are created on at first boot. Use a stable
        path - a `/dev/sdX` name is a different disk after the next reboot.
      '';
    };

    rootDevice = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Disk the image is written to. Nothing reads this - the flasher asks at
        install time, and a hand-written image goes wherever it is pointed - so
        it serves only to record the intent and to supply dataDevice's default
        when the two are the same disk.
      '';
    };

    slotSize = lib.mkOption {
      type = lib.types.str;
      example = "16G";
      description = ''
        Size of each of the two store slots.

        Deliberately without a default, because it is the one figure here worth
        measuring rather than guessing. The floor is the compressed size of the
        system closure - erofs with lz4hc brings that to roughly half of what
        `nix path-info -S` reports for `system.build.toplevel`. Falling short
        fails the image build, which is the point: the alternative is finding out
        when an update will not fit.

        It is also the figure everything else scales from. Two slots are spent
        before a single game is installed, and the flasher sizes its own store
        from the sum of the target's partitions, so an over-generous slot here
        costs roughly four times as much across the artifacts as it looks like it
        should. Trimming what the console installs pays for itself twice over.
      '';
    };

    version = lib.mkOption {
      type = lib.types.str;
      example = "3";
      description = ''
        Version stamped into the slot partition labels and the UKI filename.

        systemd-sysupdate compares these to decide what is newer, so this has to
        be bumped for every image the console is meant to accept - an image
        carrying a version it already runs is not an update.
      '';
    };
  };

  config = {
    foundrix.config = {
      image = {
        device = {
          dataDevice = cfg.dataDevice;
          rootDevice = lib.mkIf (cfg.rootDevice != null) cfg.rootDevice;
        };
        store.erofs-readonly.sizeMin =
          if isInstallMedium then lib.mkForce "1M" else lib.mkDefault cfg.slotSize;
        slots.ab.emptySlotSize = lib.mkDefault emptySlotSize;
      };

      # Uncapped, against the module's own 16G default: everything the console
      # writes - saves, shader caches, Proton prefixes and the games themselves -
      # lands here through the home overlay, so it should have the rest of the disk.
      runtime.repart.data.sizeMax = null;
    };

    # Both slots have to be the same size on the console, because an update swaps
    # their roles: a slot minimized to fit today's store would be too small to
    # receive the next one after the swap. Capping them turns "the system
    # outgrew its slot" into a build failure rather than an update that cannot
    # be applied.
    image.repart.partitions = {
      ${partitionIds.store}.repartConfig = storePartition;
      ${partitionIds.storeEmpty}.repartConfig = {
        Minimize = "off";
        SizeMaxBytes = emptySlotSize;
      };
    };

    system.image = {
      id = lib.mkDefault "game-console";
      inherit (cfg) version;
    };

    boot.uki.name = lib.mkDefault "game-console";

    # foundrix clears this to "run repart early without dependencies", which
    # removes the one ordering nixpkgs documents as required - systemd-repart
    # cannot operate on a device node udev has not created yet, and told to run
    # without waiting it frequently wins that race. Losing it means no /var, and
    # a first boot that ends in emergency mode; winning it on some later boot is
    # what makes the failure look intermittent rather than systematic.
    #
    # Requires= is left as nixpkgs sets it and pulls the device in; only the
    # ordering was missing. Overridden below mkForce because that is the
    # priority the clearing uses.
    boot.initrd.systemd.services.systemd-repart.after = lib.mkOverride 40 [
      "${utils.escapeSystemdPath cfg.dataDevice}.device"
    ];

    # Nothing on the machine can add an account: /etc is an immutable overlay on
    # a volatile root, so a user created at runtime would not survive the reboot
    # that its uid allocation is recorded across.
    users.mutableUsers = lib.mkDefault false;
  };

  # Updates, once the flake exposes the image outputs for this device:
  #
  #   nix build path:.#<config>/image:<device>:x86_64    initial install media
  #   nix build path:.#<config>/update:<device>:x86_64   UKI + store slot for sysupdate
  #   nix build path:.#<config>/updater:<device>:x86_64  bootable image that applies one
  #
  # To serve updates to the console instead of carrying them to it, import
  # foundrixModules.framework.ota on the device and point
  # foundrix.framework.ota.updateServer at where the update artifacts are
  # published; systemd-sysupdate then fetches the newer version into the idle
  # slot on its own.
}
