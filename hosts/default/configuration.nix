{ config, pkgs, pkgs-unstable, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix # Copy this from /etc/nixos/
      ../../modules/sunshine.nix   # Relative path to your modules
      ../../modules/gaming.nix
      ../../modules/1password.nix
    ];

  # --- Boot & Hardware ---
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
  boot.extraModprobeConfig = "options amdgpu ppfeaturemask=0xffffffff\n";

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      rocmPackages.clr.icd
      libva
    ];
  };
  # --- Networking ---
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  networking.interfaces.eno1.wakeOnLan.enable = true;
  networking.interfaces.wlp11s0.wakeOnLan.enable = true;

  # Firewall: Keep SSH & WoL open. Sunshine ports are handled in modules/sunshine.nix
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ];
  networking.firewall.allowedUDPPorts = [ 9 ];

  # --- Services ---
  services.openssh.enable = true;
  services.tailscale.enable = true;
  services.resolved.enable = true;
  networking.useNetworkd = false;
  # --- Desktop ---
  services.xserver = {
    enable = true;
    videoDrivers = [ "amdgpu" ];
    xkb = {
      layout = "us";
      variant = "";
    };
  };
  services.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "shyam";
  services.lact.enable = true;

  # --- Audio & Printing ---
  services.printing.enable = true;
  services.printing.drivers = [ 
    pkgs.splix
    pkgs.samsung-unified-linux-driver ];
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
    
    ## Tools ##
    glxinfo # OpenGL info
    vulkan-tools # Khronos official Vulkan Tools and Utilities
    clinfo # Print information about available OpenCL platforms and devices
    libva-utils # Collection of utilities and examples for VA-API
    
    ## Monitor ##
    lact # Linux GPU Configuration Tool for AMD and NVIDIA
    amdgpu_top # Tool to display AMDGPU usage
    nvtopPackages.amd # (h)top like task monitor for AMD, Adreno, Intel and NVIDIA GPUs
  ];
  
  programs.firefox.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;
  nix.settings.trusted-users = [ "root" "shyam"];
  
  #Garbage Collection
  nix.gc = {
  automatic = true; # Enable automatic GC service
  dates = "weekly"; # Schedule runs (e.g., "03:15", "daily", "weekly")
  options = "--delete-older-than 30d"; # Delete unreferenced paths older than 30 days
  };

  system.stateVersion = "25.05";
}
