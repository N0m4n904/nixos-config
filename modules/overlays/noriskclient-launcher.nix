{
  # nixos-26.05 builds noriskclient-launcher as a symlinkJoin that calls
  # wrapGAppsHook from postBuild. That hook now guards itself with an
  # associative array keyed on $output, which stdenv only defines inside
  # fixupPhase, so the call aborts with "bad array subscript".
  #
  # Upstream replaced the hook call with a direct wrapGApp on the launcher
  # binary (nixpkgs master). Drop this module once that reaches nixos-26.05.
  nixpkgs.overlays = [
    (final: prev: {
      noriskclient-launcher = prev.noriskclient-launcher.overrideAttrs (old: {
        buildCommand =
          builtins.replaceStrings
            [ "wrapGAppsHook" ]
            [
              ''wrapGApp "$out/bin/noriskclient-launcher-v3"''
            ]
            old.buildCommand;
      });
    })
  ];
}
