{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    foundrix = {
      url = "git+https://codeberg.org/xdevs23/foundrix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-unstable.follows = "nixpkgs-unstable";
      inputs.nixpkgs-stable.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake/beta";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Deliberately not following nixpkgs: hyprland.cachix.org only has binaries for
    # the closure built against Hyprland's own pin. Overriding it means building the
    # compositor and all of hyprwm's libraries from source on every bump.
    hyprland.url = "github:hyprwm/Hyprland/39d7e209c79d451efab1b21151d5938289da838d";
    # Plugins link against Hyprland's internals, so the rev has to come from the same
    # era as the compositor: this one is the first after "all: update for 0.55".
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins/1cb37fad68dff5f5840010c314fed5809b4ee66f";
      inputs.hyprland.follows = "hyprland";
    };
    quickshell = {
      url = "git+https://git.outfoxxed.me/quickshell/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    led-matrix-monitoring = {
      url = "github:MidnightJava/led-matrix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    joycon-colors = {
      url = "git+https://gitlab.com/N0m4n904/joy-con-color-change";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    xos-ci = {
      url = "github:halogenOS/ci/romboss";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ammaster-bridge = {
      url = "git+https://gitlab.com/N0m4n904/ammaster-bridge";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Proton-CachyOS ships as a release tarball rather than a package, so there
    # is nothing to track as a source repository. This is the release metadata
    # instead: it carries both the download URL and, since GitHub began
    # publishing asset digests, the hash to verify it with - which is the whole
    # pin, and is why updating it is `nix flake update` rather than an errand.
    # See modules/gaming/proton-cachyos.nix.
    proton-cachyos-release = {
      url = "file+https://api.github.com/repos/CachyOS/proton-cachyos/releases/latest";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      foundrix,
      ...
    }@flakeArgs:
    let
      lib = nixpkgs.lib;
      foundrixLib = foundrix.lib;
      forAllSystems = lib.genAttrs lib.systems.flakeExposed;

      # Reconstruct foundrixPackages to match what pluggedInTo used to provide.
      foundrixPackages =
        pkgs: extraArgs:
        let
          scope = extraArgs // {
            inherit pkgs;
          };
        in
        lib.filesystem.packagesFromDirectoryRecursive {
          callPackage = pkgs.newScope scope;
          newScope = extra: pkgs.newScope (scope // extra);
          directory = foundrix + "/packages";
        };

      # Build the special args that foundrix modules expect.
      specialArgs = {
        inherit foundrix foundrixPackages;
        foundrixModules = foundrix.nixosModules;
        foundrixInputs = removeAttrs flakeArgs [ "self" ];
        foundrixIgnoreMissingInputs = false;
        inputs = removeAttrs flakeArgs [ "self" ];
        currentFlake = self;
      }
      // (import (foundrix + "/special.nix") {
        inherit lib foundrix;
        currentFlake = self;
      });

      baseModules = [
        ./configuration.nix
      ];

      # The general-purpose toolkit, composed here rather than from
      # configuration.nix so that the one configuration which does without it -
      # the console, whose store is read-only and sized in advance - says so by
      # omission, in the same place its desktop environment is chosen.
      generalHome = ./home.nix;
    in
    rec {
      nixosConfigurations = {
        nixos-desktop = lib.nixosSystem {
          inherit specialArgs;
          modules = baseModules ++ [
            generalHome
            ./desktop/desktop.nix
            ./desktop/desktop-environments/gnome/gnome.nix
          ];
        };
        nixos-notebook = lib.nixosSystem {
          inherit specialArgs;
          modules = baseModules ++ [
            generalHome
            ./desktop/desktop.nix
            ./desktop/desktop-environments/cosmic/cosmic.nix
          ];
        };
        nixos-console = lib.nixosSystem {
          inherit specialArgs;
          modules = baseModules ++ [
            ./console/console.nix
            ./console/gnome.nix
          ];
        };
        nixos-server = lib.nixosSystem {
          inherit specialArgs;
          modules = baseModules ++ [
            generalHome
            ./server/server.nix
          ];
        };
      }
      // foundrixLib.deviceFramework.mkDeviceSpecificConfigurations {
        triceratops = {
          nixosConfiguration = nixosConfigurations.nixos-desktop;
          deviceConfiguration = ./desktop/devices/triceratops;
          platformModule = foundrix.nixosModules.hardware.platform.x86_64;
        };
        pteranodon = {
          nixosConfiguration = nixosConfigurations.nixos-notebook;
          deviceConfiguration = ./desktop/devices/pteranodon;
          platformModule = foundrix.nixosModules.hardware.platform.x86_64;
        };
        brachiosaurus = {
          nixosConfiguration = nixosConfigurations.nixos-server;
          deviceConfiguration = ./server/devices/brachiosaurus;
          platformModule = foundrix.nixosModules.hardware.platform.x86_64;
        };
        stegosaurus = {
          nixosConfiguration = nixosConfigurations.nixos-console;
          deviceConfiguration = ./console/devices/stegosaurus;
          platformModule = foundrix.nixosModules.hardware.platform.x86_64;
        };
      };

      # Consoles are the only image-based hosts here, and image, flasher and
      # updater artifacts are not something nixosConfigurations can express.
      # foundrix builds them from a (configuration, device) pair; pluggedInTo
      # would do this automatically but insists on pairing every configuration
      # with every device, so only the console devices are paired up, and only
      # with the console configuration.
      packages.x86_64-linux =
        let
          system = "x86_64-linux";
          pkgs = import nixpkgs { inherit system; };
          customLib = import (foundrix + "/lib") (
            specialArgs
            // {
              inherit lib;
              defaultSpecialArgs = specialArgs;
              inherit pkgs;
            }
          );
          consoleDevices = lib.attrNames (
            lib.filterAttrs (_: entryType: entryType == "directory") (builtins.readDir ./console/devices)
          );
          artifactsFor =
            device:
            (customLib.images.mkTargetOutputs {
              name = "nixos-console";
              deviceConfiguration = ./console/devices + "/${device}";
              nixosConfiguration = nixosConfigurations.nixos-console;
            }).outputs
            // {
              # foundrix builds raw disk images throughout, so the installer ISO
              # is assembled here rather than coming out of mkTargetOutputs. The
              # console it installs is the already-evaluated host of the same
              # name, which is why a device directory and its flake entry have to
              # agree.
              "nixos-console/iso:${device}:x86_64" =
                (lib.nixosSystem {
                  specialArgs = specialArgs // {
                    consoleTarget = nixosConfigurations.${device}.config;
                  };
                  modules = [
                    ./console/installer-iso.nix
                    { nixpkgs.hostPlatform = system; }
                  ];
                }).config.system.build.isoImage;
            };
        in
        lib.mergeAttrsList (map artifactsFor consoleDevices)
        // {
          build-console-installer = pkgs.callPackage ./console/build-install-image.nix { };
          serve-console-update = pkgs.callPackage ./console/serve-update.nix { };
        };

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);
    };
}
