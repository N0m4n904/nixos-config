# Builds an update for a console and serves it over HTTP for the console to
# fetch.
#
# systemd-sysupdate reads SHA256SUMS from the update server to learn which
# versions exist, then pulls the files it names. foundrix's ota-build already
# writes that file next to the artifacts, so nothing more than a static file
# server over that directory is required.
#
# Serves the compressed artifacts by default. The store image is a partition
# image sized to the whole slot, so most of it is zeroes - tens of gigabytes
# uncompressed against a small fraction of that over the wire, for the same
# bytes on arrival. sysupdate accepts either.
{
  writeShellApplication,
  nix,
  python3,
  findutils,
}:

writeShellApplication {
  name = "serve-console-update";
  runtimeInputs = [
    nix
    python3
    findutils
  ];
  text = ''
    host="''${1:-}"
    port="''${2:-8000}"
    if [ -z "$host" ]; then
      echo "usage: serve-console-update <hostname> [port]" >&2
      exit 1
    fi

    flake="''${FLAKE:-path:$PWD}"
    artifact="update@compressed"
    if [ "''${RAW:-}" = "1" ]; then
      artifact="update"
    fi

    echo "building $artifact for $host..."
    out=$(nix build --no-link --print-out-paths "$flake#nixos-console/$artifact:$host:x86_64")

    echo
    echo "serving $out"
    find "$out" -maxdepth 1 -type f -printf '  %f  (%s bytes)\n'
    echo
    echo "The console's gameConsole.updateServer must point here, and this"
    echo "machine must allow the port on the interface the console arrives on."
    echo "Scoped to Tailscale rather than opened to the whole network:"
    echo "  networking.firewall.interfaces.\"tailscale0\".allowedTCPPorts = [ $port ];"
    echo
    echo "Then, on the console:"
    echo "  systemctl start systemd-sysupdate    # or wait for the timer"
    echo "  systemd-sysupdate list               # what it can see"
    echo
    echo "The console writes it into the idle slot and boots into it next time."
    echo "Ctrl-C to stop serving."
    echo

    exec python3 -m http.server "$port" --directory "$out" --bind 0.0.0.0
  '';
}
