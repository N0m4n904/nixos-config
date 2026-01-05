{
  applyHomeManagerShared,
  pkgs,
  pkgsUnstable,
  inputs,
  ...
}:
{
  home-manager = applyHomeManagerShared rec {
    home.packages = with pkgs; [
      chromium
      discord-ptb
      easyeffects
      gimp3-with-plugins
      gnome-calculator
      gnome-terminal
      gnome-tweaks
      gparted
      inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.beta
      mangohud
      nautilus
      pkgsUnstable.noriskclient-launcher
      obs-studio
      onlyoffice-desktopeditors
      pavucontrol
      postman
      rose-pine-cursor
      signal-desktop
      telegram-desktop
      thunderbird
      vlc
      pkgsUnstable.winboat
      pkgsUnstable.android-studio
      pkgsUnstable.jetbrains.idea-oss
      pkgsUnstable.spotify
      (vesktop.override { withSystemVencord = true; })
    ];

    programs.vscode.profiles.default.extensions = with pkgs.vscode-extensions; [
      mathiasfrohlich.kotlin
      vue.volar
    ];

    xdg = {
      mimeApps.associations = {
        added = {
          "application/pdf" = "org.gnome.Evince.desktop";
          "audio/aac" = "io.github.celluloid_player.Celluloid.desktop";
          "audio/flac" = "io.github.celluloid_player.Celluloid.desktop";
          "audio/ogg" = "io.github.celluloid_player.Celluloid.desktop";
          "audio/opus" = "io.github.celluloid_player.Celluloid.desktop";
          "audio/wav" = "io.github.celluloid_player.Celluloid.desktop";
          "image/gif" = "org.gnome.Loupe.desktop";
          "image/jpeg" = "org.gnome.Loupe.desktop";
          "image/jpg" = "org.gnome.Loupe.desktop";
          "image/png" = "org.gnome.Loupe.desktop";
          "text/html" = "zen-beta.desktop";
          "text/plain" = "org.gnome.gedit.desktop";
          "text/x-log" = "org.gnome.gedit.desktop";
          "x-scheme-handler/about" = "zen-beta.desktop";
          "x-scheme-handler/http" = "zen-beta.desktop";
          "x-scheme-handler/https" = "zen-beta.desktop";
          "x-scheme-handler/tg" = "org.telegram.desktop.desktop";
          "x-scheme-handler/tonsite" = "org.telegram.desktop.desktop";
          "x-sheme-handler/discord" = "vesktop.desktop";
        };
      };
      mimeApps.defaultApplications = xdg.mimeApps.associations.added;
    };
  };
}