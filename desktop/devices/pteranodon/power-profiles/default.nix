# Dual-mode power + fan management for the Framework 16 (7940HS + RX 7700S).
#
# DEV mode (baseline / COSMIC desktop): sustained-CPU PPT + earlier fan curve.
# GAMING mode (Gamescope session): GPU-first PPT + faster heat removal.
#
# The two profiles are pure data in ./dev.nix and ./gaming.nix. This module
# turns them into fw-fanctrl strategies + an apply script each, and binds those
# to the gamescope-session lifecycle:
#   * power-profile-dev    <- multi-user.target  +  gamescope-session-recovery
#   * power-profile-gaming <- gamescope-session
#
# The shared FW16 heatpipes mean a CPU power spike can throttle the GPU; we
# shift the power envelope (PPT) rather than capping CPU frequency, so boost
# stays fully available.
#
# EPP is owned by power-profiles-daemon (what the COSMIC power widget controls),
# not written directly. Each mode transition resets the PPD profile to
# "performance"; because nothing re-asserts it on a timer, a manual change in
# the COSMIC widget sticks until the next transition (mode switch / reboot).
#
# A third BATTERY profile (./battery.nix) is applied by a watcher service while
# the COSMIC widget is set to "Power Saver" (PPD power-saver): low CPU envelope,
# Bluetooth off, dimmed display. It reverts when the widget leaves Power Saver.
{
  pkgs,
  lib,
  config,
  ...
}:
let
  profiles = {
    dev = import ./dev.nix;
    gaming = import ./gaming.nix;
  };
  battery = import ./battery.nix;

  ryzenadj = lib.getExe pkgs.ryzenadj;
  fw-fanctrl = "${config.hardware.fw-fanctrl.package}/bin/fw-fanctrl";
  powerprofilesctl = "${config.services.power-profiles-daemon.package}/bin/powerprofilesctl";
  rfkill = lib.getExe' pkgs.util-linux "rfkill";

  stateFile = "/run/power-profile.active";
  batteryMarker = "/run/power-profile.battery-active";
  savedBrightness = "/run/power-profile.saved-brightness";

  # PPT (power limits) + fan curve + active-profile marker. This is the part
  # that is safe to re-run on resume: it only touches ryzenadj (the SMU drops
  # PPT across suspend) and the fan daemon. It deliberately does NOT touch the
  # PPD/EPP profile, so a manual COSMIC change survives suspend/resume.
  mkBase =
    name: profile:
    pkgs.writeShellScript "power-profile-${name}-base" ''
      set -uo pipefail

      # system-sleep runs scripts with a minimal PATH; make coreutils (seq,
      # sleep, cat) resolvable so this works when called from the resume hook.
      export PATH="${lib.makeBinPath [ pkgs.coreutils ]}:$PATH"

      # PPT via ryzenadj. Values are in milliwatts.
      ${ryzenadj} \
        --stapm-limit=${toString profile.ppt.stapm} \
        --fast-limit=${toString profile.ppt.fast} \
        --slow-limit=${toString profile.ppt.slow} \
        --apu-slow-limit=${toString profile.ppt.apuSlow} \
        --tctl-temp=${toString profile.ppt.tctlTemp} \
        --dgpu-skin-temp=${toString profile.ppt.dgpuSkinTemp} || true

      # Fan curve via fw-fanctrl. The daemon may not have its socket ready yet
      # at boot, so retry briefly.
      for _ in $(seq 1 15); do
        if ${fw-fanctrl} use ${profile.fanStrategy} 2>/dev/null; then
          break
        fi
        sleep 1
      done

      echo ${name} > ${stateFile}
    '';

  baseScripts = lib.mapAttrs mkBase profiles;

  # Full mode-switch script: base + reset the COSMIC/PPD power profile to
  # "performance". Only runs on real mode transitions (boot, enter/exit game),
  # never on a timer, so a manual COSMIC change is respected until the next one.
  mkApply =
    name:
    pkgs.writeShellScript "power-profile-${name}" ''
      set -uo pipefail
      ${baseScripts.${name}}
      ${powerprofilesctl} set performance || true
    '';

  applyScripts = lib.mapAttrs (name: _: mkApply name) profiles;

  # --- Battery profile (COSMIC/PPD "power-saver") -------------------------------
  # The CPU envelope alone — reused by the resume hook (the SMU drops PPT on
  # suspend, so it must be re-applied while still on battery).
  batteryCpu = pkgs.writeShellScript "power-profile-battery-cpu" ''
    set -uo pipefail
    ${ryzenadj} \
      --stapm-limit=${toString battery.ppt.stapm} \
      --fast-limit=${toString battery.ppt.fast} \
      --slow-limit=${toString battery.ppt.slow} \
      --apu-slow-limit=${toString battery.ppt.apuSlow} \
      --tctl-temp=${toString battery.ppt.tctlTemp} \
      --dgpu-skin-temp=${toString battery.ppt.dgpuSkinTemp} || true
  '';

  # Enter: the one-shot side effects — Bluetooth off + dim display (saving the
  # prior brightness). Marker-gated by the watcher so brightness is saved once.
  batteryEnter = pkgs.writeShellScript "power-profile-battery-enter" ''
    set -uo pipefail
    ${lib.optionalString battery.disableBluetooth "${rfkill} block bluetooth || true"}

    : > ${savedBrightness}
    for b in /sys/class/backlight/*; do
      [ -e "$b/brightness" ] || continue
      max=$(cat "$b/max_brightness")
      echo "$b $(cat "$b/brightness")" >> ${savedBrightness}
      echo $(( max * ${toString battery.brightnessPercent} / 100 )) > "$b/brightness" 2>/dev/null || true
    done

    touch ${batteryMarker}
  '';

  # Exit: restore brightness + Bluetooth, then re-apply the active mode's CPU/fan
  # (battery never touches PPD, so the user's COSMIC choice is left alone).
  batteryExit = pkgs.writeShellScript "power-profile-battery-exit" ''
    set -uo pipefail
    if [ -f ${savedBrightness} ]; then
      while read -r dev val; do
        echo "$val" > "$dev/brightness" 2>/dev/null || true
      done < ${savedBrightness}
      rm -f ${savedBrightness}
    fi

    ${lib.optionalString battery.disableBluetooth "${rfkill} unblock bluetooth || true"}

    case "$(cat ${stateFile} 2>/dev/null || echo dev)" in
      gaming) ${baseScripts.gaming} ;;
      *)      ${baseScripts.dev} ;;
    esac

    rm -f ${batteryMarker}
  '';

  # Watcher: engage the battery profile while EITHER the COSMIC/PPD profile is
  # "power-saver" OR the battery is discharging at/below the threshold. The CPU
  # clamp is re-asserted every poll (so it survives a dev/gaming transition or
  # resume while engaged); the dim/Bluetooth side effects fire once via the
  # marker. Polling (not D-Bus) is simpler and ~4s latency is fine here. Never
  # touches PPD, so there is no feedback loop.
  batteryWatch = pkgs.writeShellScript "power-profile-battery-watch" ''
    set -uo pipefail
    while :; do
      should=0
      [ "$(${powerprofilesctl} get 2>/dev/null || echo "")" = "power-saver" ] && should=1
      ${lib.optionalString (battery.autoBelowPercent != null) ''
        for bat in /sys/class/power_supply/BAT*; do
          [ -e "$bat/capacity" ] || continue
          [ "$(cat "$bat/status" 2>/dev/null)" = "Discharging" ] || continue
          cap=$(cat "$bat/capacity" 2>/dev/null)
          [ -n "$cap" ] && [ "$cap" -le ${toString battery.autoBelowPercent} ] && should=1
        done
      ''}

      if [ "$should" = 1 ]; then
        ${batteryCpu}
        [ -e ${batteryMarker} ] || ${batteryEnter}
      else
        [ -e ${batteryMarker} ] && ${batteryExit} || true
      fi
      sleep 4
    done
  '';

  mkService = name: {
    description = "Apply ${name} power/fan profile (Framework 16)";
    # Pull in the fan daemon but do NOT order after it: fw-fanctrl is itself
    # After+WantedBy multi-user.target, so adding After=fw-fanctrl while we are
    # WantedBy=multi-user.target creates a cyclic transaction. The apply script
    # retries `fw-fanctrl use` until the daemon socket is ready instead.
    wants = [
      "fw-fanctrl.service"
      "power-profiles-daemon.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = applyScripts.${name};
    };
  };
in
{
  environment.systemPackages = [ pkgs.ryzenadj ];

  # ryzenadj needs the ryzen_smu kernel module to reach the SMU. This kernel has
  # CONFIG_STRICT_DEVMEM=y / CONFIG_IO_STRICT_DEVMEM=y, which blocks ryzenadj's
  # /dev/mem fallback ("Unable to get memory access" -> PPT limits silently fail).
  # The module exposes /dev/ryzen_smu and also restores `ryzenadj -i` monitoring.
  boot.extraModulePackages = [ config.boot.kernelPackages.ryzen-smu ];
  boot.kernelModules = [ "ryzen_smu" ];

  # The power-profile services run as root with no login session, but PPD's
  # switch-profile action only allows active local sessions. Allow root to
  # switch profiles so the services can reset the profile to "performance".
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.UPower.PowerProfiles.switch-profile" &&
          subject.user == "root") {
        return polkit.Result.YES;
      }
    });
  '';

  # Register the DEV/GAMING fan strategies and make DEV the boot default
  # (foundrix's laptop-16-7040 module sets defaultStrategy = "custom").
  hardware.fw-fanctrl.config = {
    defaultStrategy = lib.mkForce "dev";
    strategies = {
      dev = profiles.dev.fan;
      gaming = profiles.gaming.fan;
    };
  };

  systemd.services.power-profile-dev = lib.mkMerge [
    (mkService "dev")
    {
      # Boot baseline. (Restore-on-game-exit is handled by power-profile-gaming's
      # ExecStopPost, not here: this unit is RemainAfterExit, so a Wants= from the
      # recovery service would never re-run it once it is active.)
      wantedBy = [ "multi-user.target" ];
      after = [ "power-profiles-daemon.service" ];
    }
  ];

  systemd.services.power-profile-gaming = lib.mkMerge [
    (mkService "gaming")
    {
      wantedBy = [ "gamescope-session.service" ];
      # Bound to the gamescope session so it stops on EVERY exit path (recovery,
      # natural Steam quit, crash); ExecStopPost then re-applies the dev profile.
      partOf = [ "gamescope-session.service" ];
      after = [
        "gamescope-session.service"
        "power-profiles-daemon.service"
      ];
      serviceConfig.ExecStopPost = applyScripts.dev;
    }
  ];

  # Prevent the machine from auto-suspending while in Game Mode. The gamescope
  # session runs on its own TTY, so the COSMIC desktop's idle timer would
  # otherwise suspend the whole system mid-game. Hold a block inhibitor on
  # sleep+idle for the lifetime of the gamescope session.
  systemd.services.gamescope-inhibit-sleep = {
    description = "Inhibit auto-suspend/idle during the gamescope session";
    wantedBy = [ "gamescope-session.service" ];
    partOf = [ "gamescope-session.service" ];
    after = [ "gamescope-session.service" ];
    serviceConfig.ExecStart =
      "${lib.getExe' pkgs.systemd "systemd-inhibit"} "
      + "--what=sleep:idle --who=gamescope --why='Game Mode active' --mode=block "
      + "${lib.getExe' pkgs.coreutils "sleep"} infinity";
  };

  # Watch the COSMIC/PPD power profile and apply the battery profile while it is
  # set to "power-saver" (the widget's battery option).
  systemd.services.power-profile-battery-watch = {
    description = "Apply battery power/fan profile on PPD power-saver";
    wantedBy = [ "multi-user.target" ];
    after = [ "power-profiles-daemon.service" ];
    wants = [ "power-profiles-daemon.service" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = batteryWatch;
      Restart = "always";
      RestartSec = 5;
    };
  };

  # Re-apply only PPT + fan after resume — the SMU drops ryzenadj PPT limits on
  # suspend/hibernate. Uses the base scripts so PPD/EPP is left untouched.
  environment.etc."systemd/system-sleep/power-profile-resume.sh" = {
    mode = "0755";
    text = ''
      #!/bin/sh
      export PATH="${lib.makeBinPath [ pkgs.coreutils ]}:$PATH"
      case "$1" in
        post)
          if [ -e ${batteryMarker} ]; then
            ${batteryCpu}
          else
            case "$(cat ${stateFile} 2>/dev/null || echo dev)" in
              gaming) ${baseScripts.gaming} ;;
              *)      ${baseScripts.dev} ;;
            esac
          fi
          ;;
      esac
    '';
  };
}
