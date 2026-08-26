# The OS-side half of console-image.nix: how a home directory works when the
# store it was built from is read-only.
#
# Home Manager normally realises a generation during activation, which needs a
# store it can write to. config.home-manager-prebuilt bakes each home into the
# image instead and mounts it as the lower layer of an overlay rooted on /var,
# so the managed config arrives read-only and everything written over it - saves,
# shader caches, Proton prefixes, the games themselves - persists on the data
# partition. /home consequently needs no mount of its own.
#
# It cannot live in console-image.nix, which is where it belongs by subject
# matter, because the device configuration is reused verbatim to build the
# flasher and updater systems. Those are minimal systems with no Home Manager
# module, so an unconditional reference to home-manager.* fails to evaluate
# there. foundrix makes the same split for its qemu targets, guarding the import
# from outside the module system.
{ foundrixModules, ... }:

{
  imports = [
    foundrixModules.config.home-manager-prebuilt

    # Repairs the one thing the arrangement above breaks; imported from here
    # rather than from console.nix so the two always travel together.
    ./console-dconf.nix
  ];
}
