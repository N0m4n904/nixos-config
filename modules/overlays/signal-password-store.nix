{
  # Electron picks its password store by sniffing the desktop environment. Under
  # GNOME it settles on gnome-libsecret; under Hyprland it recognises nothing and
  # falls back to basic_text, which cannot decrypt a database key that was sealed
  # with libsecret. Signal then refuses to open at all.
  #
  # Naming the backend explicitly makes the choice independent of which session is
  # running. It is not a migration: the key stays where it already is, and this only
  # stops Electron guessing differently depending on how the machine was booted.
  #
  # Deliberately scoped to hosts that actually run Hyprland rather than applied in
  # the shared package list. Which store holds the key is per-machine state, so
  # forcing libsecret on a machine whose key was sealed with basic_text would break
  # Signal there in exactly the same way, only in reverse.
  #
  # A wrapper rather than the package's own commandLineArgs argument, which nixpkgs
  # deprecated in favour of exactly this, and rather than overrideAttrs, which would
  # rebuild Signal from source for the sake of one flag.
  nixpkgs.overlays = [
    (final: prev: {
      signal-desktop = final.symlinkJoin {
        name = "signal-desktop-libsecret-${prev.signal-desktop.version}";
        paths = [ prev.signal-desktop ];
        nativeBuildInputs = [ final.makeWrapper ];

        # The desktop entry runs an unqualified "signal-desktop", so it resolves
        # through PATH to this wrapper rather than around it.
        postBuild = ''
          wrapProgram $out/bin/signal-desktop \
            --add-flags '--password-store=gnome-libsecret'
        '';

        inherit (prev.signal-desktop) meta;
      };
    })
  ];
}
