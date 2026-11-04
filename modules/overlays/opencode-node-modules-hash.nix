{
  # opencode vendors its dependencies through a fixed-output derivation that runs
  # `bun install`, and the hash nixos-unstable records for opencode 2.2.5 is not
  # the one that derivation produces: every build of it fails the hash check, so
  # there is no cached opencode 2.2.5 either. The value below is what the
  # derivation actually produces on Linux, reproduced by three people
  # independently in NixOS/nixpkgs#582673.
  #
  # Scoped to the unstable package set because that is where opencode is taken
  # from. Drop this module once NixOS/nixpkgs#582675, which records the hash per
  # platform, has reached nixos-unstable.
  nixpkgs-unstable.overlays = [
    (final: prev: {
      opencode = prev.opencode.overrideAttrs (old: {
        node_modules = old.node_modules.overrideAttrs {
          outputHash = "sha256-prx9dX7kUvs/E3zopkaPk5LXh3xJAy5sZeum/W8L7cA=";
        };
      });
    })
  ];
}
