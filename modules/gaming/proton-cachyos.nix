# Proton-CachyOS as a Steam compatibility tool, tracking upstream's latest
# release through the flake lock.
#
# Upstream publishes it as a release tarball rather than a package, and names
# every asset after its version, so there is no fixed URL to point a fetcher at.
# What is fixed is the API's "latest release" endpoint, and that answer carries
# both the download URL and - since GitHub started publishing asset digests -
# the sha256 to verify it with. Locking that one document therefore pins the
# whole thing, which is why `nix flake update` is all this needs.
#
# Evaluation stays pure: nothing here asks the network what is newest. The lock
# file already recorded that answer, so a given commit builds a given system,
# which the console's A/B images depend on.
#
# Built by re-pointing proton-ge-bin's source rather than packaging it afresh,
# because the two are the same shape - a prebuilt Proton tree Steam is told
# about - and only the tarball differs.
{
  config,
  inputs,
  lib,
  pkgsUnstable,
  ...
}:

let
  cfg = config.protonCachyos;

  release = builtins.fromJSON (builtins.readFile inputs.proton-cachyos-release);

  # Selected by suffix rather than rebuilt from the tag, so the name comes from
  # upstream in one piece. The levels do not overlap: an x86_64_v3 asset ends in
  # "_v3.tar.xz" and so is never mistaken for the plain x86_64 one.
  candidates = lib.filter (
    asset: lib.hasSuffix "-${cfg.architecture}.tar.xz" asset.name
  ) release.assets;

  asset = lib.head candidates;

  # The directory inside the tarball, which is also the string upstream wrote
  # into compatibilitytool.vdf - proton-ge-bin substitutes the display name over
  # exactly this text, and fails the build if it cannot find it.
  toolName = lib.removeSuffix ".tar.xz" asset.name;

  tarball = pkgsUnstable.fetchurl {
    url = asset.browser_download_url;
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
    version = release.tag_name;

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

      There is no matching option for the version. That comes from the locked
      release metadata, and is moved with `nix flake update proton-cachyos-release`
      or held still by leaving the lock alone.
    '';
  };

  config = {
    assertions = [
      {
        assertion = candidates != [ ];
        message = ''
          No ${cfg.architecture} build in Proton-CachyOS ${release.tag_name}. It published:
          ${lib.concatMapStringsSep "\n" (a: "  ${a.name}") release.assets}
        '';
      }
      {
        assertion = candidates == [ ] || (asset.digest or null) != null;
        message = ''
          Proton-CachyOS ${release.tag_name} publishes no digest for ${asset.name},
          so there is no hash to pin it with. Releases from before GitHub added
          asset digests need pinning by hand instead.
        '';
      }
    ];

    # A list, so this merges with whatever else a host offers Steam rather than
    # replacing it.
    programs.steam.extraCompatPackages = [ package ];
  };
}
