# Brings every pin in this configuration up to date.
#
# `nix flake update` alone is no longer the whole story: Proton-CachyOS is
# pinned by a committed file rather than a flake input, because the document
# upstream publishes it through cannot be locked. This puts the two halves back
# behind one command, so updating stays a single thing to type and neither half
# can be forgotten.
#
# Takes no arguments, and updates everything. To move one flake input on its
# own, `nix flake update <input>` still does exactly that.
{
  writeShellApplication,
  git,
  update-proton-cachyos,
}:

writeShellApplication {
  name = "update";

  runtimeInputs = [
    git
    update-proton-cachyos
  ];

  # Nix itself is deliberately not among those: the lock file should be written
  # by the Nix that is going to read it, which is the one already on PATH.
  text = ''
    if [ "$#" -ne 0 ]; then
      echo "update: takes no arguments; use 'nix flake update <input>' for a single input" >&2
      exit 2
    fi

    repo=$(git rev-parse --show-toplevel)

    nix flake update --flake "path:$repo"
    update-proton-cachyos "$repo/modules/gaming/proton-cachyos-release.json"
  '';
}
