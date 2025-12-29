{
  description = "My Modular NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home Manager
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # --- NEW: Hardware support for Surface devices ---
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, nixos-hardware, ... }@inputs: 
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    
    # Define unstable pkgs
    pkgs-unstable = import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    nixosConfigurations = {
      # Your Desktop (Existing)
      nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs pkgs-unstable; };
        modules = [
          ./hosts/default/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs pkgs-unstable; };
            home-manager.users.shyam = import ./home/default/home.nix;
          }
        ];
      };

      # --- NEW: Your Surface Laptop ---
      surface-book-active = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs pkgs-unstable; };
        modules = [
          # 1. Surface Hardware Module (Replaces <nixos-hardware/...>)
          nixos-hardware.nixosModules.microsoft-surface-common

          # 2. System Configuration
          ./hosts/surface-book-active/configuration.nix

          # 3. Home Manager
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs pkgs-unstable; };
            home-manager.users.shyam = import ./home/surface-book-active/home.nix;
          }
        ];
      };
      surface-book-passive = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs pkgs-unstable; };
        modules = [
          # 1. Surface Hardware Module (Replaces <nixos-hardware/...>)
          nixos-hardware.nixosModules.microsoft-surface-common

          # 2. System Configuration
          ./hosts/surface-book-passive/configuration.nix

          # 3. Home Manager
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs pkgs-unstable; };
            home-manager.users.shyam = import ./home/surface-book-passive/home.nix;
          }
       ];
    };
  };
  };
  }
