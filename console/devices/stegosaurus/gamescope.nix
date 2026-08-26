# What this particular graphics card needs from the compositor.
#
# Split out from the device configuration rather than written inline there,
# because the device is read a second time to build the flasher and the updater.
# Those are minimal systems that never import the gamescope session module, so
# an unconditional reference to foundrix.config.gamescope-session fails to
# evaluate for them - the same trap console-home.nix documents, and guarded the
# same way, by importing this only when a full system is being built.
#
# It is here rather than in console/console.nix because none of it generalises:
# a console built on a card from this decade wants every one of these left
# alone. The rest of the session tuning that is not about the GPU - dropping
# CAP_SYS_NICE so Steam's sandbox will start, and the realtime scheduling that
# depends on it - stays with the OS configuration, where it applies to any
# hardware.
{ ... }:

{
  foundrix.config.gamescope-session = {
    # --force-composition is deliberately absent, having been tried and removed.
    #
    # It was added because NVIDIA reports zero DRM format modifiers for the FP16
    # formats, which looked like the direct scan-out path failing. Those errors
    # are real but not fatal - gamescope logs them and carries on with 8-bit
    # formats - and the problem it was actually meant to solve, Steam refusing to
    # start, turned out to be CAP_SYS_NICE reaching bubblewrap instead.
    #
    # What it does do is disable direct scan-out and force every frame through
    # the compositing path, which on this driver is the path producing black
    # frames and, on waking, corrupted ones. Steam's own Big Picture renders
    # correctly on the same card through GNOME, so neither the card nor the
    # driver is incapable of presenting; only this path is.
    #
    # If the blanking survives its removal, the conclusion is that gamescope on
    # the proprietary NVIDIA driver is not a configuration worth pursuing here,
    # and Big Picture under GNOME is the console this machine can actually run.
    extraArgs = [ ];

    # No variable refresh rate to offer: G-Sync needs DisplayPort, and the HDMI
    # this is plugged into predates HDMI 2.1. Asking the compositor for it buys
    # nothing even when it works, and gamescope proved willing to crash outright
    # when told to drive a connector that cannot do it.
    adaptiveSync = false;

    # Presenting without waiting for vblank, on a path that is already
    # compositing every frame because scan-out does not work here. Turning it
    # off did not fix the screen going black between repaints, so this is not
    # the cause of that - but asking for a lower-latency flip from a pipeline
    # that cannot deliver one is not worth keeping on the strength of having
    # been the default.
    immediateFlips = false;

    # MangoHud's overlay process dumps core on this driver every time it is
    # launched. It is not what kills gamescope - that happens with the overlay
    # disabled too - but an overlay that reliably segfaults is worth less than
    # nothing.
    mangoapp = false;
  };
}
