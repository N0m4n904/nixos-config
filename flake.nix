{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.05";
    foundrix = {
      url = "git+https://codeberg.org/xdevs23/foundrix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    linux-nitrous = {
      url = "file+https://gitlab.com/xdevs23/linux-nitrous/-/raw/v6.17.8-2-nixos/default.nix";
      flake = false;
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
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
      nixosConfigurations = {
        nixos-desktop = lib.nixosSystem {
          specialArgs = self.nixosModules.foundrixSpecialArgs;
          modules = [
            ./configuration.nix
            ./desktop-environments/gnome.nix
          ];
        };
        # This is how you create variants of your OS. You don't have to use the "@" character,
        # but it might be a good convention to communicate that it's just a variant of the same base config.
        #"nixos-desktop@hyprland" = lib.nixosSystem {
        #  specialArgs = self.nixosModules.foundrixSpecialArgs;
        #  modules = [
        #    ./configuration.nix
        #    ./desktop-environments/hyprland.nix
        #  ];
        #};
      }
      // foundrixLib.deviceFramework.mkDeviceSpecificConfigurations {
        # Here's where you actually configure your hosts.
        # The hostname is the attribute name.
        # The networking.hostName config will be set by the device framework.
        # That allows you to use the same exact configuration on multiple machines while
        # still being able to name them differently.
        triceratops = {
          nixosConfiguration = nixosConfigurations.nixos-desktop;
          deviceConfiguration = ./devices/triceratops;
          platformModule = foundrix.nixosModules.hardware.platform.x86_64;
        };
      };
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);
    };
}
