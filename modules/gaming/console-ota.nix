# Lets the console fetch its own updates, rather than waiting for someone to
# arrive with the updater USB stick.
#
# systemd-sysupdate asks the update server for SHA256SUMS, sees which versions
# are on offer, and writes any newer one into whichever store slot is not
# running. Nothing is switched at that point - the new slot only takes over at
# the next boot, and the slot it replaced remains as the way back.
#
# OS-side rather than device-side, and for the same reason as SSH: the device
# configuration is reused to build the flasher and the updater, and the updater
# recipe sets up transfers of its own that read from the USB stick. Handing it a
# second set pointed at the network would have the two disagree about where an
# update comes from.
{
  config,
  foundrixModules,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.gameConsole;

  # Where the answer to "is an update waiting" is left for Steam to read. In
  # /run because it describes what the server is offering right now, and a stale
  # answer surviving a reboot would be worse than no answer.
  availableFile = "/run/game-console-update-available";
in
{
  imports = [
    foundrixModules.framework.ota
  ];

  options.gameConsole.updateServer = lib.mkOption {
    type = lib.types.str;
    example = "http://build-host:8000/";
    description = ''
      Where the console looks for updates - a plain static file server over the
      directory that `nix run path:.#serve-console-update` publishes.

      Deliberately without a default. Which machine publishes updates is a fact
      about one installation rather than about consoles in general, and a module
      that guessed would quietly point somebody else's console at a host that
      does not exist. It is set with the rest of the OS configuration instead.

      Prefer a name that resolves over the tailnet to an address on the local
      network, so it keeps working when the console moves or the router hands
      out different leases. Whichever machine is named has to allow the port on
      the interface the console reaches it by.
    '';
  };

  config = {
    foundrix.framework.ota.updateServer = cfg.updateServer;

    # Game mode offers OS updates through Steam's own button, which reaches this
    # unit via modules/gaming/steamos-update.nix. Steam runs as the user, and
    # applying an update writes a partition, so the one unit it needs has to be
    # startable without a password - the alternative is a prompt nobody can
    # answer with a controller.
    #
    # Deliberately these two units alone rather than a general grant. Note that
    # this cannot be a sudo rule instead: Steam's container sets no_new_privs,
    # so sudo refuses to escalate from inside it no matter how sudoers is
    # written. polkit authorises the request at systemd rather than at the
    # caller, which is what makes it reachable from in there at all.
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.systemd1.manage-units" &&
            subject.user == ${builtins.toJSON cfg.user} &&
            ["systemd-sysupdate.service", "console-update-check.service"]
              .indexOf(action.lookup("unit")) >= 0) {
          return polkit.Result.YES;
        }
      });
    '';

    # Asking whether an update is waiting needs root - sysupdate reads the ESP
    # and the partition table, and as the user it stops at "Failed to resolve
    # '/EFI/Linux' (relative to '/boot'): Permission denied". Since the caller
    # cannot become root, the question is answered on its behalf here and the
    # result left somewhere it can read.
    #
    # The version on offer is taken from what check-new prints rather than from
    # its exit status, so nothing depends on a convention that is not documented
    # and would fail silently if it changed: a version means an update, no
    # output means none.
    # A store slot is eight gigabytes over a home network, so an update takes
    # long enough to cross an idle timeout - and a console spends that time
    # showing nothing, which is exactly what convinces a desktop session to
    # suspend. Waking up afterwards leaves the version half written, and
    # sysupdate refuses to resume it: "Selected update is already acquired and
    # partially installed. Vacuum it to try installing again."
    #
    # Holding the lock for the duration is better than trusting the idle policy
    # to stay disabled, since anything that suspends the machine mid-transfer
    # costs the whole download. The reconstructed command is upstream's own;
    # there is no option to prepend to it.
    #
    # The empty string first is required, not decorative: this lands as a
    # drop-in over a unit systemd itself ships, and ExecStart= is a list, so a
    # bare assignment would append to upstream's rather than replace it. A
    # Type=simple service refuses to start with two of them.
    systemd.services.systemd-sysupdate.serviceConfig.ExecStart = lib.mkForce [
      ""
      "${lib.getExe' pkgs.systemd "systemd-inhibit"} --what=idle:sleep --why=\"Applying an OS update\" ${pkgs.systemd}/lib/systemd/systemd-sysupdate update"
    ];

    systemd.services.console-update-check = {
      description = "Record whether an OS update is being offered";

      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "game-console-update-check" ''
          ${lib.getExe' pkgs.systemd "systemd-sysupdate"} check-new > ${availableFile}.new 2>/dev/null || true
          ${lib.getExe' pkgs.coreutils "mv"} -f ${availableFile}.new ${availableFile}
        '';
      };
    };

    # foundrix leaves this as "auto", which sysupdate documents as "the block
    # device which contains the root file system of the currently booted
    # system". This root is a tmpfs and has no such device, so the lookup fails
    # with "Failed to determine block device of file system" and no update can
    # ever be applied - the same assumption about there being a real root that
    # breaks repart's non-initrd run.
    #
    # The store partitions live on whichever disk the image was written to,
    # which nothing here knows for certain because the installer asks at the
    # time. On a console with one drive that is the same disk the runtime
    # partitions go on, which is the case worth supporting.
    systemd.sysupdate.transfers."20-store-remote".Target.Path = lib.mkForce (
      config.gameConsole.image.dataDevice
    );

    # sysupdate verifies the manifest's detached GPG signature by default,
    # against a keyring at /etc/systemd/import-pubring.pgp. foundrix's ota-build
    # publishes SHA256SUMS and no signature at all, so with the default left
    # alone every update is refused before a byte is downloaded.
    #
    # Turning it off is not as bad as it sounds and not as good as signing: the
    # payloads are still checked against the SHA256 hashes in the manifest, so
    # what is lost is authentication of the manifest itself. Whoever can answer
    # for the update server can serve a different system - which here means
    # anyone who can impersonate a host on the tailnet, over a transport that is
    # already authenticated and encrypted. Publishing over the open internet
    # would want a signature instead.
    systemd.sysupdate.transfers = {
      # [Transfer], not [Source] - sysupdate parses unknown keys with a warning
      # and carries on, so getting the section wrong looks like the setting was
      # simply ignored rather than misplaced.
      "10-uki-remote".Transfer.Verify = false;
      "20-store-remote".Transfer.Verify = false;

      # Which partitions are even candidates. Left unset sysupdate looks for
      # linux-generic, while foundrix labels the store slots with a type GUID of
      # its own, so nothing matches and the update stops at "Partition type must
      # be set for partition targets".
      #
      # Read back from the partition that defines it rather than written out
      # again, so the two cannot drift apart.
      "20-store-remote".Target.MatchPartitionType =
        config.image.repart.partitions.${config.foundrix.config.image.partition-ids.store}.repartConfig.Type;
    };

    systemd.sysupdate = {
      # Upstream's schedule spreads checks over a four-hour random delay, which
      # suits a fleet that must not stampede one server and defeats the point
      # here, where the question is usually "did the console pick up the update
      # I just published". A console is also rarely powered on for long, so a
      # check shortly after boot matters more than any calendar.
      #
      # These land as a drop-in over systemd's own unit, where single-valued
      # directives replace but list-valued ones accumulate - so upstream's
      # weekly OnCalendar has to be reset explicitly rather than simply not
      # mentioned, or it survives as a stray extra trigger.
      timerConfig = {
        OnBootSec = "2min";
        OnUnitActiveSec = "1h";
        RandomizedDelaySec = "1min";
        Persistent = true;
        OnCalendar = "";
      };

      # Left off deliberately, and worth keeping off: this timer reboots once an
      # update has been staged, on a fixed nightly schedule. A television is a
      # bad place to discover that the machine has decided 04:10 is a convenient
      # moment. The new slot is picked up whenever the console is next switched
      # on, which is the natural moment anyway.
      reboot.enable = false;
    };
  };
}
