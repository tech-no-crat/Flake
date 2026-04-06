# modules/nix-settings.nix
# Nix daemon and flakes configuration
{ ... }:

{
  nix.settings = {
    # Allows specified users to perform privileged Nix operations
    trusted-users = [ "root" "shyam" ];
    
    # Enable flakes and new nix command
    experimental-features = [ "nix-command" "flakes" ];
  };

  # Note: Per-host secret keys and trusted-public-keys should be added
  # in individual host configurations if needed
}
