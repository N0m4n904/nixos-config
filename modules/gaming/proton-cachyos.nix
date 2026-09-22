# Proton-CachyOS as a Steam compatibility tool, pinned to one upstream release.
#
# Upstream publishes it as a release tarball rather than a package, and names
# every asset after its version, so there is no fixed URL to point a fetcher at.
# What upstream does publish is a release document naming the assets and - since
# GitHub started publishing asset digests - the sha256 to verify each one with.
# The pin is a copy of the few fields of that document which describe a release,
# committed beside this file and refreshed with `nix run .#update-proton-cachyos`.
#
# Copied rather than tracked as a flake input because the same document carries
# a download counter per asset. Those move continuously, so its hash changed
# without a release ever being published, and every locked hash went stale
# within days - leaving evaluation to fail on a mismatch nothing had caused.
#
# Evaluation stays pure: nothing here asks the network what is newest. The
# committed metadata already answers that, so a given commit builds a given
# system, which the console's A/B images depend on.
#
# Built by re-pointing proton-ge-bin's source rather than packaging it afresh,
# because the two are the same shape - a prebuilt Proton tree Steam is told
# about - and only the tarball differs.
{
  config,
  lib,
  pkgsUnstable,
  ...
}:

let
  cfg = config.protonCachyos;

  release = builtins.fromJSON (builtins.readFile ./proton-cachyos-release.json);

  # Kept lazy so that an architecture the pinned release does not offer is
  # reported by the assertion below, rather than as a missing attribute.
  asset = release.assets.${cfg.architecture} or null;

  # The directory inside the tarball, which is also the string upstream wrote
  # into compatibilitytool.vdf - proton-ge-bin substitutes the display name over
  # exactly this text, and fails the build if it cannot find it.
  toolName = lib.removeSuffix ".tar.xz" asset.name;

  tarball = pkgsUnstable.fetchurl {
    url = asset.url;
    sha256 = lib.removePrefix "sha256:" asset.digest;
  };

  # proton-ge-bin sets dontUnpack and symlinks the contents of src, so src has to
  # be a directory. fetchzip would give one, but it hashes the unpacked tree,
  # and the digest upstream publishes is of the tarball - so unpack it here
  # instead, stripping the single root directory the way fetchzip would.
  src = pkgsUnstable.runCommand "${toolName}-unpacked" { } ''
    mkdir -p "$out"
    tar -xJf ${tarball} --strip-components=1 -C "$out"
  '';

  package = pkgsUnstable.proton-ge-bin.overrideAttrs (_: {
    inherit src toolName;
    pname = "proton-cachyos";
    version = release.tag;

    # Deliberately says nothing about the version. Steam records the chosen
    # compatibility tool per game under this name, so folding the release into
    # it would silently reset every one of those choices on each update.
    steamDisplayName = "Proton-CachyOS-latest";
  });
in
{
  options.protonCachyos.architecture = lib.mkOption {
    type = lib.types.str;
    default = "x86_64_v3";
    description = ''
      Which of the release's builds to use. Upstream ships `x86_64`, `x86_64_v3`
      and `arm64`; there is no v4 build, despite the microarchitecture existing.

      There is no matching option for the version. That comes from the pinned
      release metadata, which `nix run .#update` moves along with every flake
      input, `nix run .#update-proton-cachyos` moves on its own, and leaving
      the file alone holds still.
    '';
  };

  config = {
    assertions = [
      {
        assertion = release.assets ? ${cfg.architecture};
        message = ''
          No ${cfg.architecture} build in Proton-CachyOS ${release.tag}. It published:
          ${lib.concatMapStringsSep "\n" (name: "  ${name}") (lib.attrNames release.assets)}
        '';
      }
    ];

    # A list, so this merges with whatever else a host offers Steam rather than
    # replacing it.
    programs.steam.extraCompatPackages = [ package ];
  };
}
