{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    foundrix = {
      url = "git+https://codeberg.org/xdevs23/foundrix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-unstable.follows = "nixpkgs-unstable";
      inputs.home-manager.follows = "home-manager";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake/beta";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
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
    in
    foundrix.nixosModules.pluggedInTo flakeArgs rec {
      deviceRoots = [
        ./desktop/devices
        ./server/devices
      ];
      nixosConfigurations = {
        nixos-desktop = lib.nixosSystem {
          specialArgs = self.nixosModules.foundrixSpecialArgs;
          modules = [
            ./configuration.nix
            ./desktop/desktop.nix
            ./desktop/desktop-environments/gnome/gnome.nix
          ];
        };
        nixos-notebook = lib.nixosSystem {
          specialArgs = self.nixosModules.foundrixSpecialArgs;
          modules = [
            ./configuration.nix
            ./desktop/desktop.nix
            ./desktop/desktop-environments/cosmic/cosmic.nix
          ];
        };
        nixos-server = lib.nixosSystem {
          specialArgs = self.nixosModules.foundrixSpecialArgs;
          modules = [
            ./configuration.nix
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
      };
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);
    };
}
