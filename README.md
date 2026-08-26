# NixOS Configuration
My personal NixOS configuration, using:
- NixOS Stable
- foundrix
- Gnome
- COSMIC
- Hyprland

---

# Console PC

`console/` holds a Steam Deck style host: it boots straight into Steam's game
mode, keeps a desktop one menu entry away, and runs from a read-only store in
one of two A/B slots. Because that store is a partition image, it has no
`nixos-rebuild switch` — it is updated by building a new image and handing it
over.

## Installing

```bash
nix run path:.#build-console-installer <hostname>
```

Produces an ISO carrying the console's disk image. Write it to a USB drive with
`dd`, or drop it on a Ventoy stick, then boot the console from it: it lists the
drives it can see, leaving out the one it booted from, asks which to install to,
and writes the image. Nothing is downloaded during the install.

`RAW_FLASHER=1` builds the same installer as a raw disk image instead, and
`DISK_IMAGE=1` builds the console's disk itself, for writing straight to the
target drive over a USB enclosure.

## Shipping an update

```bash
nix run path:.#serve-console-update <hostname> [port]
```

1. Bump `gameConsole.image.version` in `console/devices/<hostname>/`.
   systemd-sysupdate compares versions, so an unchanged one is silently ignored.
2. Run the command on a machine the console can reach — its
   `gameConsole.updateServer` names which one.
3. The console checks two minutes after boot and hourly thereafter, or on demand
   with `systemctl start systemd-sysupdate`.

The update lands in whichever slot is not running and is picked up at the next
boot; the slot it replaced stays behind as the way back. `/var` is untouched, so
the game library survives.

Both commands take the hostname of the console, e.g. `stegosaurus`, and wrap the
flake's per-device artifact outputs, which are also available directly:

```bash
nix build path:.#'nixos-console/iso:<hostname>:x86_64'        # installer ISO
nix build path:.#'nixos-console/flasher:<hostname>:x86_64'    # same, as a raw image
nix build path:.#'nixos-console/image:<hostname>:x86_64'      # the console's disk
nix build path:.#'nixos-console/updater:<hostname>:x86_64'    # offline update stick
nix build path:.#'nixos-console/update:<hostname>:x86_64'     # artifacts to serve
```

---

# LICENSE

```
Copyright (C) 2025  Noah Anleitner

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
```

The code in this repository is licensed under the **GNU General Public License v3.0 (GPL-3.0)** only - See [LICENSE](LICENSE)