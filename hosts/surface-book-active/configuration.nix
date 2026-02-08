{ config, pkgs, pkgs-unstable, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix 
    ];

  # --- Boot & Hardware ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  networking.hostName = "surface-book-active";
  
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vaapiIntel
  };

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["intel" "nvidia"];
  
  hardware.nvidia = {
    # Modesetting is required
    modesetting.enable = true;
    
    # Enable the NVIDIA settings menu
    nvidiaSettings = true;

    # Use the open source kernel module (Turing+ GPUs)
    open = true;

    # Use stable driver
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # PRIME configuration
    prime = {
      # Use "offload" (recommended for laptops) or "sync"
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      
      # !!! ADJUST THESE BUS IDs !!!
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };

    # Power management (fine-grained is experimental, disable if it causes issues)
    powerManagement.enable = false;
    powerManagement.finegrained = false;
  };
  # --- Networking ---
  networking.networkmanager.enable = true;
  time.timeZone = "America/New_York";
  
  # --- Localization ---
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # --- Desktop Environment ---
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
    xkb.layout = "us";
    xkb.variant = "";
  };
# for >25.11
#  services.displayManager.gdm.enable = true;
#  services.desktopManager.gnome.enable = true;
   
  # --- Services ---
  services.printing.enable = true;
  services.tailscale.enable = true;
  services.openssh.enable = true;

  # Docker (Virtualization)
  virtualisation.docker.enable = true;

  # Audio
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # --- User Setup ---
  users.users.shyam = {
    isNormalUser = true;
    description = "Shyam Shukla";
    # Added "docker" group so you don't need sudo for docker commands
    extraGroups = [ "networkmanager" "wheel" "docker" ]; 
  };

  # --- System Programs ---
  programs.firefox.enable = true;

  # 1Password (System-level integration for Polkit)
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "shyam" ];
  };

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.trusted-users = [ "root" "shyam"];
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
  ];

  system.stateVersion = "25.05";
}
