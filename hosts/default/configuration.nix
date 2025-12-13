{ config, pkgs, pkgs-unstable, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix # Copy this from /etc/nixos/
      ../../modules/sunshine.nix   # Relative path to your modules
      ../../modules/steam.nix
      ../../modules/1password.nix
    ];

  # --- Boot & Hardware ---
  hardware.graphics.enable = true;
  hardware.enableRedistributableFirmware = true;
  hardware.uinput.enable = true;
  boot.kernelPackages = pkgs-unstable.linuxPackagaes_latest;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.kernelParams = [ 
    "video=DP-1:2560x1440@144"
    "video=DP-2:2560x1440@144"
    "amdgpu.vm_fragment_size=9"
    ];
  boot.kernelModules = [ "iwlwifi" ]; 
  boot.blacklistedKernelModules = [ "radeon" ];
   
  # --- Networking ---
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  
  # Firewall: Keep SSH & WoL open. Sunshine ports are handled in modules/sunshine.nix
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ];
  networking.firewall.allowedUDPPorts = [ 9 ];

  # --- Services ---
  services.openssh.enable = true;
  services.tailscale.enable = true;
  
  # --- Desktop ---
  services.xserver = {
    enable = true;
    videoDrivers = [ "amdgpu" ];
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
  };
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "shyam";

  # --- Audio & Printing ---
  services.printing.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # --- User Setup ---
  users.users.shyam = {
    isNormalUser = true;
    description = "shyam";
    extraGroups = [ "networkmanager" "wheel" "uinput" "input" ];
    # Notice: No 'packages' list here! They are all in home.nix now.
  };

  # --- System Packages ---
  # Only install tools needed by root or for debugging here
  environment.systemPackages = with pkgs; [
    vim
    wget
  ];
  
  programs.firefox.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "25.05";
}
