# A real ISO that carries the console's disk image and writes it to a drive you
# pick.
#
# The flasher recipe foundrix builds does the same job, but as a raw disk image:
# it has to be dd'd, which claims the whole stick, and it is a partition table
# rather than a filesystem, so tools built around ISO files have at best partial
# support for it. An ISO9660 image is the format those tools are designed for,
# is still dd-able, and costs nothing extra - the payload dominates either way.
#
# Nothing is downloaded during the install. The image travels inside the ISO,
# which matters for a machine that has no operating system yet and may not have
# a network the installer can reach.
{
  config,
  consoleTarget,
  foundrix,
  lib,
  modulesPath,
  pkgs,
  ...
}:

let
  # Called straight from foundrix's tree rather than through the foundrixPkgs
  # module argument, which only exists in systems importing foundrix's own
  # baseline - this is a stock NixOS installer ISO and has no reason to.
  flasher-tui = pkgs.callPackage (foundrix + "/packages/flasher-tui") { };

  inherit (consoleTarget.networking) hostName;
  version = consoleTarget.system.image.version;

  targetImage = "${consoleTarget.system.build.image}/${consoleTarget.image.fileName}";

  # The console's disk is two slots of which one is empty, and the full one has
  # slack, so most of the image is zeroes and compresses away to very little.
  # The uncompressed size travels with it because the writer needs to know how
  # far it is going to get for its progress bar - it cannot learn that from a
  # stream it is decompressing as it goes.
  payload =
    pkgs.runCommand "console-install-payload"
      {
        nativeBuildInputs = [
          pkgs.zstd
          pkgs.coreutils
        ];
      }
      ''
        mkdir -p "$out"
        zstd -T0 -9 ${targetImage} -o "$out/image.raw.zst"
        stat -c %s ${targetImage} > "$out/uncompressed-size"
      '';

  # foundrix's picker, reused rather than reimplemented: it lists the drives it
  # can see, leaves out the one it booted from, asks before writing, and shows
  # progress. It decompresses zstd itself.
  # The size is read with the shell's own builtin rather than by calling out to
  # cat, so this script depends on nothing but the interpreter named in its
  # shebang. The picker needs a PATH of its own; this wrapper should not.
  installer = pkgs.writeShellScript "console-installer" ''
    read -r image_size < /iso/install/uncompressed-size

    exec ${lib.getExe flasher-tui} \
      --image /iso/install/image.raw.zst \
      --image-name ${lib.escapeShellArg "${hostName} (image ${version})"} \
      --image-size "$image_size"
  '';
in
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  # baseName rather than fileName: the ISO is written out as
  # "''${image.baseName}.iso", while fileName is derived from baseName and only
  # feeds image.filePath. Setting fileName alone renames nothing.
  # Forced because iso-image.nix composes its own name from the NixOS label at
  # the same priority, and that name says nothing about which console this
  # installs.
  image.baseName = lib.mkForce "${hostName}-installer-${version}";

  isoImage = {
    volumeID = lib.substring 0 11 "${lib.toUpper hostName}INST";

    contents = [
      {
        source = payload;
        target = "/install";
      }
    ];
  };

  # An installer that only writes a prepared image to a disk has no use for a
  # filesystem it will never touch, and it is not a small one to carry.
  boot.supportedFilesystems.zfs = lib.mkForce false;

  # Takes over the first console instead of the login prompt that would
  # otherwise be there: this medium does one thing, and asking someone to find
  # and run a command would only be a step between them and it. The remaining
  # TTYs keep their getty, so there is still a way to a shell if the install
  # needs looking into.
  systemd.services.console-installer = {
    description = "Install ${hostName} to a disk";
    wantedBy = [ "multi-user.target" ];
    conflicts = [ "getty@tty1.service" ];
    after = [ "systemd-user-sessions.service" ];

    # Everything the picker shells out to: lsblk and findmnt to enumerate disks
    # and check they are idle, blockdev to make the kernel re-read the partition
    # table it just wrote, and systemctl for the reboot it offers at the end.
    # Set as a list rather than as a bare PATH= so that adding a dependency here
    # cannot silently remove the rest.
    path = [
      pkgs.util-linux
      pkgs.coreutils
      config.systemd.package
    ];

    serviceConfig = {
      Type = "idle";
      ExecStart = installer;
      StandardInput = "tty-force";
      StandardOutput = "tty";

      # To the console rather than only the journal. A medium whose single
      # purpose is to run this has nowhere useful to hide a failure: sending it
      # to the journal turns any error into a blank screen and a machine that
      # looks hung.
      StandardError = "tty";

      TTYPath = "/dev/tty1";
      TTYReset = true;
      TTYVHangup = true;
      Restart = "on-failure";
      RestartSec = 3;
    };

    # Retry a couple of times, then stop and leave the reason on screen. Without
    # a limit a failure that will never come right just scrolls past itself
    # forever, which buries the one line worth reading.
    startLimitIntervalSec = 60;
    startLimitBurst = 3;
  };

  # This ISO is built from its own nixosSystem and so never sees the
  # configuration.nix that sets this for every other host here. Left alone it
  # would come up with a US layout, on the one medium where the whole
  # interaction is a keyboard.
  console.keyMap = "de-latin1";

  system.stateVersion = consoleTarget.system.stateVersion;
}
