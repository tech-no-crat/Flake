{
  description = "My Modular NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, nixos-hardware, ... }@inputs:
  let
    system = "x86_64-linux";
    pkgs-unstable = import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };

    # Helper: create a nixosConfiguration with all modules declared in one place
    mkNixosConfig = { configPath, homeConfigPath, modules ? [], hardwareModules ? [] }:
      nixpkgs-unstable.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs pkgs-unstable; };
        modules = hardwareModules ++ modules ++ [
          configPath
          home-manager.nixosModules.home-manager
          {
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs pkgs-unstable; };
            home-manager.users.shyam = import homeConfigPath;
          }
        ];
      };

  in {
    nixosConfigurations = {
      # Desktop: AMD GPU, gaming, streaming
      nixos = mkNixosConfig {
        configPath = ./hosts/nixos/configuration.nix;
        homeConfigPath = ./home/nixos/home.nix;
        modules = [
          ./modules/hyprland.nix
          ./modules/audio.nix
          ./modules/sunshine.nix
          ./modules/gaming.nix
          ./modules/multimedia.nix
          ./modules/1password.nix
        ];
      };

      # Surface Book (Active): NVIDIA GPU, portable
      surface-book-active = mkNixosConfig {
        configPath = ./hosts/surface-book-active/configuration.nix;
        homeConfigPath = ./home/surface-book-active/home.nix;
        hardwareModules = [ nixos-hardware.nixosModules.microsoft-surface-common ];
        modules = [
          ./modules/gnome.nix
          ./modules/audio-laptop.nix
          ./modules/surface-common.nix
          ./modules/nvidia-surface.nix
          ./modules/1password.nix
        ];
      };

      # Surface Book (Passive): Intel iGPU, remote deployment
      surface-book-passive = mkNixosConfig {
        configPath = ./hosts/surface-book-passive/configuration.nix;
        homeConfigPath = ./home/surface-book-passive/home.nix;
        hardwareModules = [ nixos-hardware.nixosModules.microsoft-surface-common ];
        modules = [
          ./modules/gnome.nix
          ./modules/audio-laptop.nix
          ./modules/surface-common.nix
          ./modules/intel-surface.nix
          ./modules/1password.nix
        ];
      };
    };
  };
}
