{
  applyHomeManagerShared,
  foundrixPkgs,
  inputs,
  pkgs,
  pkgsUnstable,
  ...
}:
{
  home-manager = applyHomeManagerShared rec {
    home.language = {
      base = "en_US.UTF-8";
      measurement = "de_DE.UTF-8";
      monetary = "de_DE.UTF-8";
      name = "de_DE.UTF-8";
      paper = "de_DE.UTF-8";
      time = "de_DE.UTF-8";
    };

    home.packages = with pkgs; [
      apktool
      bat
      bc
      brotli
      ccache
      celluloid
      chromium
      cliphist
      curl
      ddrescue
      dig
      discord-ptb
      dysk
      e2fsprogs
      easyeffects
      evince
      fastfetch
      fd
      file
      file-roller
      foundrixPkgs.git-aliases
      foundrixPkgs.pickrange
      gedit
      gimp3-with-plugins
      git
      git-repo
      gnome-calculator
      gnome-terminal
      gnome-tweaks
      gparted
      hwloc
      imagemagick
      inetutils
      inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.beta
      iptables
      jdk
      jq
      lm_sensors
      loupe
      mangohud
      nautilus
      nftables
      nixpkgs-fmt
      ntfs3g
      obs-studio
      onlyoffice-desktopeditors
      p7zip
      pavucontrol
      pciutils
      picocom
      playerctl
      postman
      prismlauncher
      protobuf
      pv
      pwgen
      rose-pine-cursor
      rsync
      signal-desktop
      simple-scan
      smartmontools
      socat
      stress
      subfinder
      telegram-desktop
      thunderbird
      tree
      unzip
      via
      vlc
      vulkan-tools
      wl-clipboard
      wl-clipboard-x11
      woeusb-ng
      xmlstarlet
      zip
      zstd
      pkgsUnstable.android-studio
      pkgsUnstable.jetbrains.idea-community
      pkgsUnstable.nixd
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