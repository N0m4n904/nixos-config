# Steam Deck session model: the machine boots straight into Steam's game mode,
# and the desktop becomes a deliberate detour rather than the default.
#
# foundrix's gamescope-session module already provides both sessions and the
# switch between them, but it assumes a desktop came first - switching is driven
# by a user-level unit that records the session it is leaving. At boot there is
# no such session, so what is missing is an entry point, plus a way to decide
# which of the two the boot lands in. Everything else here reuses that module.
{
  applyHomeManagerShared,
  config,
  foundrixModules,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.gameConsole;

  # Which session was chosen, held as a file rather than as unit state, so the
  # display manager and the boot path can each gate on it without knowing about
  # the other. It lives in /run, so a reboot always lands back in game mode
  # instead of resuming a desktop somebody left open.
  desktopMarker = "/run/game-console-desktop-session";

  # Prerequisites the session runner is normally handed by switch-to-gamemode,
  # restated on every start so the unit can also come up on its own - at boot,
  # and again when it restarts after Steam quits, by which point its own
  # ExecStopPost has cleaned the user file away.
  claimSession = pkgs.writeShellScript "game-console-claim-session" ''
    # Not unconditional: switch-to-gamemode writes this first and is entitled to
    # name a different user than the one the console logs in as.
    [ -e /run/gamescope-session-user ] || echo ${cfg.user} > /run/gamescope-session-user
    ${lib.getExe' pkgs.coreutils "rm"} -f ${desktopMarker}
  '';

  # Runs from the desktop session's autostart. The marker is what stops this
  # becoming a loop: coming back from game mode sets it, so the desktop stays
  # put until the next boot clears it - it lives in /run.
  enterGameMode = pkgs.writeShellScript "console-enter-game-mode" ''
    [ -e ${desktopMarker} ] && exit 0

    # Wait for the session to finish arriving before taking it away again.
    # switch-to-gamemode records what it is leaving and then stops the display
    # manager, and handed a session that is still assembling it records a
    # half-built one - the desktop appears for an instant and the machine is
    # left on a bare TTY with nothing started. Entering by hand afterwards
    # works, which is what says this is a race rather than a broken path.
    for _ in $(${lib.getExe' pkgs.coreutils "seq"} 1 60); do
      ${lib.getExe' pkgs.systemd "systemctl"} --user is-active --quiet graphical-session.target && break
      ${lib.getExe' pkgs.coreutils "sleep"} 0.5
    done

    # And a moment beyond that: the target going active means the session's
    # units have started, not that the compositor has finished settling.
    ${lib.getExe' pkgs.coreutils "sleep"} 3

    exec ${lib.getExe' pkgs.systemd "systemctl"} --user start gamescope-switch.service
  '';

  # gamescope, with its output sent to the journal instead of to the screen.
  #
  # greetd hands the session the virtual terminal itself, as its stdin, stdout
  # and stderr, so StandardOutput= on the service never reaches the compositor -
  # everything it prints goes straight to tty7. That is the text scrolling past
  # while game mode starts, and it is also the reason none of it is anywhere
  # afterwards: `journalctl -u gamescope-session` has three lines in it, and the
  # log you actually want is in a console buffer that is overwritten as soon as
  # something else draws.
  #
  # Substituting the compositor is the one point in the chain this configuration
  # owns, since foundrix runs it by absolute path through the wrapper that is
  # rebuilt above. systemd-cat execs rather than forks, so the process that ends
  # up running is still gamescope with the same PID - which the session script
  # writes to its pidfile, and the watchdog below reads.
  loggedGamescope = pkgs.writeShellScript "gamescope-logged" ''
    exec ${lib.getExe' pkgs.systemd "systemd-cat"} \
      --identifier=gamescope \
      --stderr-priority=warning \
      ${lib.getExe config.programs.gamescope.package} "$@"
  '';

  # How the console notices that game mode is not coming up at all.
  #
  # greetd is configured with the session script as both its initial session and
  # its fallback greeter, so a session that dies is started again immediately.
  # From systemd's side nothing has gone wrong - the unit is running, greetd is
  # alive - which means Restart=, the start limit and OnFailure= never see
  # anything to act on. The failure lives entirely inside greetd's retry loop,
  # and the console sits on a black TTY for as long as it is left there. This
  # watchdog is what turns that back into something the system can respond to.
  #
  # Liveness is judged on the compositor, and it has to stay up rather than
  # merely appear: a session crashing and being restarted every few seconds
  # would otherwise keep passing the check at any single moment. What this
  # cannot see is a compositor that runs but shows nothing - Steam failing to
  # start behind a healthy gamescope still counts as up.
  #
  # Read from the PID the session records rather than by matching process names,
  # which is both exact and the same thing foundrix's recovery reads to find the
  # compositor it has to kill. Matching the name would not work anyway:
  # gamescope renames its main thread to gamescope-wl once it is running, so the
  # obvious `pgrep -x gamescope` matches a healthy session no better than a dead
  # one.
  gameModeHealth = pkgs.writeShellScript "game-console-game-mode-health" ''
    stateDir="/run/user/$(${lib.getExe' pkgs.coreutils "id"} -u ${cfg.user})/gamescope-session"
    deadline=$(( $(${lib.getExe' pkgs.coreutils "date"} +%s) + ${toString cfg.rescue.timeout} ))
    alive=0

    while [ "$(${lib.getExe' pkgs.coreutils "date"} +%s)" -lt "$deadline" ]; do
      # Somebody chose the desktop while we were waiting, or recovery has
      # already run for another reason. Either way there is nothing to rescue.
      ${lib.getExe' pkgs.systemd "systemctl"} is-active --quiet gamescope-session.service || exit 0

      # The session writes this immediately after launching the compositor, so
      # a start that never got that far leaves either no file or a stale PID -
      # greetd's retry overwrites it on each attempt.
      pid=""
      [ -r "$stateDir/gamescope.pid" ] && read -r pid < "$stateDir/gamescope.pid"

      # Two ways of seeing the same process, because a false positive here tears
      # down a session that was working - which is worse than failing to rescue
      # one that was not. The pidfile is the precise answer but depends on the
      # switch having prepared the state directory first; matching the binary
      # the wrapper execs into covers the case where it did not.
      if { [ -n "$pid" ] && ${lib.getExe' pkgs.coreutils "kill"} -0 "$pid" 2>/dev/null; } \
        || ${lib.getExe' pkgs.procps "pgrep"} -f ${lib.escapeShellArg "^${lib.getExe config.programs.gamescope.package} "} >/dev/null 2>&1; then
        alive=$(( alive + 1 ))
        [ "$alive" -ge ${toString cfg.rescue.settle} ] && exit 0
      else
        alive=0
      fi

      ${lib.getExe' pkgs.coreutils "sleep"} 1
    done

    echo "game mode did not come up within ${toString cfg.rescue.timeout}s; returning to the desktop" >&2

    # --no-block because recovery stops the session this unit is bound to, so
    # waiting for it to finish would mean waiting for our own teardown.
    exec ${lib.getExe' pkgs.systemd "systemctl"} start --no-block gamescope-session-recovery.service
  '';
in
{
  imports = [
    foundrixModules.config.gamescope-session
    ./steam-shortcuts.nix
  ];

  options.gameConsole = {
    enable = lib.mkEnableOption ''
      booting into Steam's game mode, with the desktop reachable from Steam's
      session menu and on the next boot after that
    '';

    user = lib.mkOption {
      type = lib.types.str;
      description = ''
        Account the console logs in as. Owns both the game mode session and the
        desktop it switches to.
      '';
    };

    rescue = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Return to the desktop when game mode fails to come up, rather than
          leaving the console on a black screen with no way back that does not
          involve a keyboard and a second machine.

          Worth turning off only when debugging the session itself, where being
          dropped back to GNOME mid-investigation is the unhelpful outcome.
        '';
      };

      timeout = lib.mkOption {
        type = lib.types.ints.positive;
        default = 60;
        description = ''
          Seconds game mode is given to bring a compositor up before the console
          gives up on it and goes back to the desktop.

          Generous on purpose: the session's own startup handshake allows ten
          seconds, and greetd retries, so anything much shorter would abandon a
          session that was merely slow on the second attempt.
        '';
      };

      settle = lib.mkOption {
        type = lib.types.ints.positive;
        default = 5;
        description = ''
          Seconds the compositor has to stay up before game mode counts as
          working. This is what distinguishes a session that started from one
          crashing and being restarted in a loop, which would otherwise be
          indistinguishable from a healthy one at any single moment.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # The session script runs /run/wrappers/bin/gamescope by absolute path, and
    # nixpkgs only creates that path when programs.gamescope.capSysNice is on -
    # otherwise gamescope is installed as an ordinary package instead. Turning
    # the capability off, which console.nix does because Steam's sandbox refuses
    # to start while holding it, therefore also deletes the file the session
    # runs. The result is not an error anyone sees: gamescope never starts, the
    # startup handshake times out, and greetd quietly runs the same script again.
    #
    # So the path is put back without the capability. A security wrapper with no
    # capabilities and no setuid bit is a plain exec passthrough - it clears the
    # loader's unsecure environment variables and hands over - which is all the
    # session needs from it.
    security.wrappers = lib.mkIf (!config.programs.gamescope.capSysNice) {
      gamescope = {
        owner = "root";
        group = "root";
        source = loggedGamescope;
      };
    };

    assertions = [
      {
        assertion =
          config.programs.gamescope.capSysNice
          || (config.programs.gamescope.args == [ ] && config.programs.gamescope.env == { });
        message = ''
          The wrapper above is built from programs.gamescope.package directly,
          which bypasses the argument and environment wrapper nixpkgs would
          otherwise put around it - so programs.gamescope.args and
          programs.gamescope.env would be silently dropped in game mode.

          Pass them through foundrix.config.gamescope-session.extraArgs instead,
          which the session script applies itself.
        '';
      }
    ];

    # Entering game mode means asking systemd, as the user, to start a system
    # unit. foundrix already permits that, but only for a subject polkit can see
    # on a local seat - and the script tears the display manager down before it
    # asks, which destroys the only seat session the user has. The stop is
    # allowed, everything after it is refused, and the console is left with no
    # display manager and no game mode. Its built-in fallback to recovery is
    # refused for the same reason, which is why nothing puts the desktop back.
    #
    # Only a console arranged this way runs into it: with the default of leaving
    # the desktop running on another VT the session survives the switch, which
    # is why the same configuration works on a workstation.
    #
    # So the same grant is restated without the locality test. What replaces it
    # is a narrower subject - the console account rather than everyone in
    # "users" - over the identical set of units, which stays derived from the
    # display manager actually configured rather than written out by hand.
    security.polkit.extraConfig =
      let
        displayManagers = lib.filter (
          name: lib.elem "display-manager.service" (config.systemd.services.${name}.aliases or [ ])
        ) (lib.attrNames config.systemd.services);

        units = lib.concatMapStringsSep ", " (unit: ''"${unit}.service"'') (
          [
            "gamescope-session"
            "gamescope-session-recovery"
            "display-manager"
          ]
          ++ displayManagers
        );
      in
      ''
        polkit.addRule(function(action, subject) {
          if (action.id == "org.freedesktop.systemd1.manage-units" &&
              subject.user == ${builtins.toJSON cfg.user} &&
              [${units}].indexOf(action.lookup("unit")) >= 0) {
            return polkit.Result.YES;
          }
        });
      '';

    foundrix.config.gamescope-session = {
      enable = true;

      # One session at a time. The default keeps game mode on a spare TTY beside
      # a live desktop, which suits a workstation paying a visit to Steam; on a
      # console it would mean a desktop idling behind Steam for the whole uptime.
      restartDisplayManager = true;
    };

    services.displayManager.autoLogin = {
      enable = true;
      user = cfg.user;
    };

    users.users.${cfg.user} = {
      # Kept from when game mode was started cold at boot and needed the runtime
      # directory to predate it. The desktop login now creates it, but game mode
      # still writes its PID there and losing it costs the precise kill path in
      # recovery, so there is nothing to gain by removing it.
      linger = true;

      # Access to the GPU, the network and input devices by group rather than by
      # logind's device ACLs. Entering game mode from a live desktop session
      # should carry those ACLs along, which is how the same configuration works
      # on a workstation - but the console has been through enough sessions that
      # did not, and group membership does not depend on which session is
      # active.
      extraGroups = [
        "video"
        "render"

        # Steam's own network panel is the only way to join a network from game
        # mode, and it drives NetworkManager over D-Bus. Membership here is what
        # polkit checks; without it the console has working networking that
        # Steam cannot see, let alone change.
        "networkmanager"

        # Controllers, for the same reason as the GPU: /dev/input/event* is
        # root:input and logind's ACLs only reach the active seat session. The
        # failure is a confusing one - enough of a controller works to look
        # connected while the sticks do nothing, and because nothing on screen
        # then changes, the compositor stops presenting and the television
        # decides it has lost the signal.
        "input"
      ];
    };

    # Game mode is entered from a desktop session rather than started cold at
    # boot, which is the arrangement the foundrix session was built for.
    # switch-to-gamemode records the session it is leaving - the VT it was on,
    # whether Steam was running, the display environment - and recovery reads
    # that back to return you. Started from a systemd unit at boot there is no
    # such session to record, and beyond a degraded way back, game mode inherits
    # none of what a login sets up: an activated seat, device ACLs, a user bus.
    #
    # So the desktop comes up first, logs in, and hands over. The cost is a
    # desktop loading on the way to Steam; the gain is that game mode is reached
    # the same way here as on a workstation, which is the arrangement that
    # actually works.
    home-manager = applyHomeManagerShared {
      home.file.".config/autostart/console-game-mode.desktop".text = ''
        [Desktop Entry]
        Type=Application
        Name=Enter Game Mode
        Comment=Hand over to Steam once the desktop session is up
        Exec=${enterGameMode}
        X-GNOME-Autostart-enabled=true
      '';
    };

    systemd.services = {
      gamescope-session = {
        # Steam quitting on its own - as opposed to being stopped by a session
        # switch - would otherwise leave a bare TTY with no way back in. Restart=
        # is deliberately not honoured after an explicit `systemctl stop`, which
        # is how the desktop switch ends this unit, so the two do not fight.
        serviceConfig = {
          ExecStartPre = claimSession;
          Restart = lib.mkForce "on-success";
          RestartSec = 2;

          # foundrix asks for Type=idle, which systemd honours by holding the
          # program back until the job queue drains - or five seconds, whichever
          # comes first. Its only purpose is to keep service output from
          # interleaving with boot messages, which is worth nothing here: game
          # mode is entered from a desktop that finished booting long ago, and
          # the console it would tidy is one this configuration now silences.
          #
          # Five seconds of a twelve-second wait, for a benefit that does not
          # apply.
          Type = lib.mkForce "simple";
        };

        # Should game mode prove unable to stay up, stop retrying and let the
        # unit fail, which hands over to the recovery path and lands on a
        # desktop somebody can debug from.
        startLimitIntervalSec = 60;
        startLimitBurst = 3;
      };

      # Every route back to the desktop - Steam's session menu, the
      # desktop-switch unit, the watchdog below, and game mode failing - runs
      # through this one unit.
      gamescope-session-recovery.serviceConfig.ExecStartPre = "${lib.getExe' pkgs.coreutils "touch"} ${desktopMarker}";

      gamescope-session-health = lib.mkIf cfg.rescue.enable {
        description = "Watch for a game mode session that never comes up";

        # Started alongside game mode and torn down with it, so a deliberate
        # switch to the desktop cancels the watch rather than leaving it to
        # time out against a session that is gone on purpose.
        after = [ "gamescope-session.service" ];
        wantedBy = [ "gamescope-session.service" ];
        partOf = [ "gamescope-session.service" ];

        serviceConfig = {
          Type = "oneshot";
          ExecStart = gameModeHealth;
        };
      };
    };
  };
}
