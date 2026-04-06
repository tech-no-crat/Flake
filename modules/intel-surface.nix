# modules/intel-surface.nix
# Intel iGPU configuration for Surface Book Passive (no NVIDIA)
{ pkgs, ... }:

{
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
    ];
  };

  services.xserver.videoDrivers = ["intel"];
}
