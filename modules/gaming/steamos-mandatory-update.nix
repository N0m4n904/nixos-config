# Answers the mandatory-update gate that Steam's first-run wizard will not move
# past.
#
# -steamos3 is what gives the console Steam's session menu, and with it the way
# back to the desktop without a keyboard. The cost is that Steam believes it is
# running on a Steam Deck, so the setup wizard insists on a firmware check
# before it will let anyone reach the login screen. It shells out to
# jupiter-initial-firmware-update; a console that is not a Deck has no such
# program, the check comes back 127, and the wizard reports "unable to download
# the required update (2)" and refuses to continue.
#
# Unlike the OS update button - which is answered honestly, see
# steamos-update.nix - this one is a stub, and it is the rare case where the
# stub is also the truth: there is no Valve firmware on this hardware, so there
# is genuinely nothing to check and nothing to apply.
#
# Steam calls it two ways, seen in the strings in steamui.so:
#
#   jupiter-initial-firmware-update check  -> "failed to run steamos-mandatory-update check"
#   jupiter-initial-firmware-update        -> "failed to apply steamos mandatory update"
#
# The exit codes are documented nowhere reachable, so both were established on
# the hardware. 7 means a firmware update is pending: it puts the wizard on the
# Deck firmware screen, whose Install button runs the apply form and then has
# nothing to show for it, because there is no firmware here to update. 0 is the
# answer that means nothing is pending and lets the wizard move on.
#
# 127 - what a missing program returns - is the third case, and the one that
# started all this: it produces "failed to run steamos-mandatory-update check"
# and the wizard stops at "unable to download the required update (2)". A
# non-zero status is not itself read as failure, since 7 is accepted quietly, so
# what mattered was the program existing at all.
#
# Getting past the firmware gate only exposes the wizard's OS update step, which
# cannot be satisfied from out here either - see the -testoobeupdater reasoning
# in console/console.nix for how that one is answered.
#
# Note that Steam invokes this as
# `PATH="''${SYSTEM_PATH-''${PATH}}" jupiter-initial-firmware-update`, against
# the host's PATH rather than the container's - so unlike steamos-update this
# has to be in environment.systemPackages, not only in Steam's FHS.
{ writeShellApplication }:

writeShellApplication {
  name = "jupiter-initial-firmware-update";

  text = ''
    exit 0
  '';

  meta.description = "Reports the Steam Deck firmware this console does not have as up to date";
}
