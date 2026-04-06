# modules/nvidia-surface.nix
# NVIDIA GPU configuration for Surface Book Active (with Intel integration)
{ config, pkgs, ... }:

{
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
    ];
  };

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

    # PRIME configuration for hybrid graphics
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      
      # Adjust these BUS IDs based on your hardware
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };

    # Power management
    powerManagement.enable = false;
    powerManagement.finegrained = false;
  };
}
