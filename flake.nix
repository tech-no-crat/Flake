{
  description = "My Modular NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Add Home Manager
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, ... }@inputs: 
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    
    # Define unstable pkgs here so it's available everywhere
    pkgs-unstable = import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      inherit system;
      
      # Pass inputs (like pkgs-unstable) to all modules
      specialArgs = { inherit inputs pkgs-unstable; };

      modules = [
        # Your System Config
        ./hosts/default/configuration.nix

        # Home Manager Module
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          
          # Pass arguments to Home Manager too
          home-manager.extraSpecialArgs = { inherit inputs pkgs-unstable; };
          
          # Where your user config lives
          home-manager.users.shyam = import ./home/default/home.nix;
        }
      ];
    };
  };
}
