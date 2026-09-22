# Refreshes the pinned Proton-CachyOS release metadata from upstream.
#
# This is a script rather than a flake input because GitHub's release document
# cannot serve as one: it embeds a download counter per asset, so its hash moves
# without a release ever being published, and a locked narHash goes stale within
# days. Only the few fields recorded here actually describe a release, and they
# change exactly when upstream publishes - so committing them makes the pin hold
# still, and updating it a deliberate act with a readable diff.
#
# See modules/gaming/proton-cachyos.nix.
{
  writeShellApplication,
  coreutils,
  curl,
  git,
  jq,
}:

writeShellApplication {
  name = "update-proton-cachyos";

  runtimeInputs = [
    coreutils
    curl
    git
    jq
  ];

  text = ''
    release_file="''${1:-$(git rev-parse --show-toplevel)/modules/gaming/proton-cachyos-release.json}"
    previous=$(jq -r .tag "$release_file" 2>/dev/null || echo "nothing")

    tmp=$(mktemp)
    trap 'rm -f "$tmp"' EXIT

    # Keyed by architecture so the module can pick one without searching, and
    # named by stripping the prefix upstream builds out of the tag rather than
    # matching a list of architectures this script would then have to learn
    # about. The digest is kept verbatim: it is upstream's own statement about
    # the tarball, and nothing here is in a position to improve on it.
    curl --fail --silent --show-error --location \
      https://api.github.com/repos/CachyOS/proton-cachyos/releases/latest \
      | jq '
          .tag_name as $tag
          | {
              tag: $tag,
              assets: (
                [
                  .assets[]
                  | select(.name | endswith(".tar.xz"))
                  | {
                      key: (.name | ltrimstr("proton-" + $tag + "-") | rtrimstr(".tar.xz")),
                      value: { name: .name, url: .browser_download_url, digest: .digest },
                    }
                ]
                | from_entries
              ),
            }
          | if (.assets | length) == 0 then
              error("\(.tag) publishes no .tar.xz assets")
            elif any(.assets[]; .digest == null) then
              error("\(.tag) publishes no digest for every build; releases from before GitHub added asset digests need pinning by hand")
            else
              .
            end
        ' > "$tmp"

    install -m 0644 "$tmp" "$release_file"
    echo "proton-cachyos: $previous -> $(jq -r .tag "$release_file")"
  '';
}
