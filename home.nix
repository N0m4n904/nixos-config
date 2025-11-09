{
  applyHomeManagerShared,
  pkgs,
  pkgsUnstable,
  foundrixPkgs,
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
      rose-pine-cursor
      jq
      pv
      pwgen
      socat
      pavucontrol
      playerctl
      git
      curl
      wl-clipboard
      cliphist
      wl-clipboard-x11
      easyeffects
      nautilus
      file-roller
      loupe
      gedit
      gnome-calculator
      mangohud
      celluloid
      dig
      signal-desktop
      unzip
      file
      zstd
      tree
      bat
      fd
      brotli
      gparted
      picocom
      telegram-desktop
      chromium
      protobuf
      e2fsprogs
      lm_sensors
      fastfetch
      pkgsUnstable.jetbrains.idea-community
      jdk
      pkgsUnstable.nixd
      nixpkgs-fmt
      bc
      imagemagick
      thunderbird
      evince
      stress
      subfinder
      ntfs3g
      woeusb-ng
      smartmontools
      rsync
      vlc
      p7zip
      iptables
      nftables
      inetutils
      simple-scan
      via
      hwloc
      inputs.zen-browser.packages.${pkgs.system}.beta
      gimp3-with-plugins
      zip

      # Gnome
      pkgs.gnome-tweaks
      gnome-terminal

      # AOSP stuff
      git-repo
      xmlstarlet
      ccache
      apktool

      (vesktop.override { withSystemVencord = true; })
      pkgsUnstable.spotify
      pkgsUnstable.android-studio
      prismlauncher
      postman
      dysk
      vulkan-tools
      discord-ptb
      onlyoffice-desktopeditors
      foundrixPkgs.git-aliases
      foundrixPkgs.pickrange
    ]
    ++ lib.optionals (osConfig.networking.hostName == "triceratops") [
      ddrescue
      obs-studio
      pciutils
    ];
    programs.vscode.profiles.default.extensions = with pkgs.vscode-extensions; [
      vue.volar
      mathiasfrohlich.kotlin
    ];
    xdg = {
      mimeApps.associations = {
        added = {
          "application/pdf" = "org.gnome.Evince.desktop";
          "text/html" = "zen-beta.desktop";
          "text/x-log" = "org.gnome.gedit.desktop";
          "x-scheme-handler/http" = "zen-beta.desktop";
          "x-scheme-handler/https" = "zen-beta.desktop";
          "x-scheme-handler/about" = "zen-beta.desktop";
          "image/png" = "org.gnome.Loupe.desktop";
          "image/jpg" = "org.gnome.Loupe.desktop";
          "image/jpeg" = "org.gnome.Loupe.desktop";
          "image/gif" = "org.gnome.Loupe.desktop";
          "audio/aac" = "io.github.celluloid_player.Celluloid.desktop";
          "audio/flac" = "io.github.celluloid_player.Celluloid.desktop";
          "audio/ogg" = "io.github.celluloid_player.Celluloid.desktop";
          "audio/wav" = "io.github.celluloid_player.Celluloid.desktop";
          "audio/opus" = "io.github.celluloid_player.Celluloid.desktop";
          "x-scheme-handler/tg" = "org.telegram.desktop.desktop";
          "x-scheme-handler/tonsite" = "org.telegram.desktop.desktop";
          "x-sheme-handler/discord" = "vesktop.desktop";
          "text/plain" = "org.gnome.gedit.desktop";
        };
      };
      mimeApps.defaultApplications = xdg.mimeApps.associations.added;
    };
  };
}
