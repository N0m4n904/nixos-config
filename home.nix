{
  applyHomeManagerShared,
  foundrixPkgs,
  pkgs,
  pkgsUnstable,
  ...
}:
{
  home-manager = applyHomeManagerShared {
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
      cliphist
      curl
      ddrescue
      dig
      dysk
      e2fsprogs
      evince
      fastfetch
      fd
      file
      file-roller
      foundrixPkgs.git-aliases
      foundrixPkgs.pickrange
      gedit
      git
      git-repo
      hwloc
      imagemagick
      inetutils
      iptables
      jdk
      jq
      lm_sensors
      loupe
      nftables
      nixpkgs-fmt
      ntfs3g
      opencode
      p7zip
      pciutils
      picocom
      playerctl
      protobuf
      pv
      pwgen
      rsync
      simple-scan
      sshfs
      smartmontools
      socat
      stress
      subfinder
      tree
      unzip
      vim
      vulkan-tools
      wl-clipboard
      wl-clipboard-x11
      woeusb-ng
      xmlstarlet
      zip
      zstd
      pkgsUnstable.nixd
    ];
  };
}