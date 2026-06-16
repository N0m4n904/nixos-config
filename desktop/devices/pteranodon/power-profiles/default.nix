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

  ryzenadj = lib.getExe pkgs.ryzenadj;
  fw-fanctrl = "${config.hardware.fw-fanctrl.package}/bin/fw-fanctrl";
  powerprofilesctl = "${config.services.power-profiles-daemon.package}/bin/powerprofilesctl";

  stateFile = "/run/power-profile.active";

  # PPT (power limits) + fan curve + active-profile marker. This is the part
  # that is safe to re-run on resume: it only touches ryzenadj (the SMU drops
  # PPT across suspend) and the fan daemon. It deliberately does NOT touch the
  # PPD/EPP profile, so a manual COSMIC change survives suspend/resume.
  mkBase =
    name: profile:
    pkgs.writeShellScript "power-profile-${name}-base" ''
      set -uo pipefail

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

  # Re-apply only PPT + fan after resume — the SMU drops ryzenadj PPT limits on
  # suspend/hibernate. Uses the base scripts so PPD/EPP is left untouched.
  environment.etc."systemd/system-sleep/power-profile-resume.sh" = {
    mode = "0755";
    text = ''
      #!/bin/sh
      case "$1" in
        post)
          active=$(cat ${stateFile} 2>/dev/null || echo dev)
          case "$active" in
            gaming) ${baseScripts.gaming} ;;
            *)      ${baseScripts.dev} ;;
          esac
          ;;
      esac
    '';
  };
}
