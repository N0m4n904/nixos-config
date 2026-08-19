{
  applyHomeManagerShared,
  lib,
  pkgs,
  ...
}:

let
  # The discrete GPU by its PCI path. There are two amdgpu hwmon devices on this
  # machine - the 7950X's iGPU is one as well - and hwmon indices reshuffle across
  # boots, so neither the index nor the driver name identifies the card. The PCI
  # slot does.
  dgpu = "/sys/devices/pci0000:00/0000:00:01.1/0000:01:00.0/0000:02:00.0/0000:03:00.0";

  # Reports whatever is audible, not one hardcoded app: Spotify, a YouTube tab in
  # Zen (which registers as firefox.instance_*), anything speaking MPRIS. A playing
  # player wins over a paused one; browser videos often carry no artist tag, so the
  # line degrades to just the title.
  mediaStatus = pkgs.writeShellScript "conky-media-status" ''
    playerctl=${lib.getExe pkgs.playerctl}

    player=""
    fallback=""
    for candidate in $("$playerctl" -l 2>/dev/null); do
      status=$("$playerctl" -p "$candidate" status 2>/dev/null) || continue
      if [ "$status" = "Playing" ]; then
        player=$candidate
        break
      fi
      [ -z "$fallback" ] && fallback=$candidate
    done
    player="''${player:-$fallback}"

    [ -z "$player" ] && {
      echo "Nothing playing"
      exit 0
    }

    artist=$("$playerctl" -p "$player" metadata artist 2>/dev/null)
    title=$("$playerctl" -p "$player" metadata title 2>/dev/null)
    track="''${artist:+$artist — }$title"
    track="''${track:0:48}"

    if [ "$("$playerctl" -p "$player" status 2>/dev/null)" = "Playing" ]; then
      echo "▶ $track"
    else
      echo "⏸ $track"
    fi
  '';

  # A plain conky file with only the store paths substituted in, rather than a config
  # assembled in Nix - conky's own syntax is ''${...}, which a Nix string would bury
  # under escapes.
  conkyConf = pkgs.replaceVars ./conky/conky.conf {
    panelLua = ./conky/panel.lua;
    inherit dgpu mediaStatus;
  };
in
{
  home-manager = applyHomeManagerShared {
    # Pulled in by gnome-session.target rather than graphical-session.target, which
    # Hyprland and COSMIC also reach - the same isolation the Hyprland units get from
    # hyprland-session.target, in the other direction.
    systemd.user.services.conky = {
      Unit = {
        Description = "Conky desktop widget";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${lib.getExe pkgs.conky} --config=${conkyConf}";
        Restart = "on-failure";
      };

      Install.WantedBy = [ "gnome-session.target" ];
    };
  };
}
