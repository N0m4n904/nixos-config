# Builds the bootable installer for a console, by hostname.
#
# This is the stick you boot on the machine you are installing: an ISO carrying
# a compressed copy of the console's disk image, and a picker that lists the
# drives it can see, skipping the one it booted from, and writes to the one you
# choose. Nothing is fetched during the install.
#
# The flake's own output names carry the configuration, the device and the
# architecture - accurate, and a mouthful to type. This asks only what actually
# varies between invocations.
{
  writeShellApplication,
  nix,
  findutils,
}:

writeShellApplication {
  name = "build-console-installer";
  runtimeInputs = [
    nix
    findutils
  ];
  text = ''
    host="''${1:-}"
    if [ -z "$host" ]; then
      echo "usage: build-console-installer <hostname>" >&2
      exit 1
    fi

    # path: rather than a bare dot, so uncommitted edits are part of the build
    # instead of being silently skipped.
    flake="''${FLAKE:-path:$PWD}"

    artifact="iso"
    if [ "''${RAW_FLASHER:-}" = "1" ]; then
      artifact="flasher"
    elif [ "''${DISK_IMAGE:-}" = "1" ]; then
      artifact="image"
    fi

    echo "building $artifact for $host..."
    out=$(nix build --no-link --print-out-paths "$flake#nixos-console/$artifact:$host:x86_64")

    echo
    echo "$out"
    find "$out" -maxdepth 1 -type f -printf '  %f  (%s bytes)\n'
    echo

    if [ "$artifact" = "iso" ]; then
      echo "Write it to a USB drive, or drop it on a Ventoy stick alongside"
      echo "whatever else lives there:"
      echo "  sudo dd if=$out/<name>.iso of=/dev/<usb> bs=4M status=progress conv=fsync"
      echo
      echo "Boot the console from it. It lists the drives it can see, leaving out"
      echo "the one it booted from, asks which to install to, and writes the image."
      echo "Nothing is downloaded - the image travels inside the ISO."
    elif [ "$artifact" = "flasher" ]; then
      echo "The same installer as a raw disk image rather than an ISO. dd works,"
      echo "tools that expect an ISO do not:"
      echo "  sudo dd if=$out/<name>.raw of=/dev/<usb> bs=4M status=progress conv=fsync"
    else
      echo "This is the console's disk itself, not an installer. Write it straight"
      echo "to the target drive - over a USB enclosure, or from a live system on"
      echo "the console:"
      echo "  sudo dd if=$out/<name>.raw of=/dev/<disk> bs=4M status=progress conv=fsync"
    fi

    echo
    echo "Either way this lays down a partition table. Treat it as a fresh"
    echo "install - to deliver an update, use serve-console-update instead."
  '';
}
