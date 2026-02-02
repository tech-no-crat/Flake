# modules/creative.nix
{ config, pkgs, pkgs-unstable, ... }:

{
  # 1. Content Creation Packages
  environment.systemPackages = [
    # Video Editing
    pkgs.davinci-resolve       # Professional color & editing
    pkgs.kdenlive              # Great "daily driver" for quick H.264 edits
    
    # OBS Studio (Wrapped with essential plugins)
    (pkgs.wrapOBS {
      plugins = with pkgs.obs-studio-plugins; [
        wlrobs                 # Wayland screen capture
        obs-backgroundremoval  # AI background removal
        obs-pipewire-audio-capture
      ];
    })

    # Modern Photo & Graphics
    pkgs.krita                 # Modern painting & photo editing (better UI than GIMP)
    pkgs.gimp                  # The standard for photo manipulation
    pkgs.darktable             # Professional RAW photo developer (Lightroom alternative)
    pkgs.inkscape              # Vector graphics (Illustrator alternative)
    pkgs.blender               # 3D modeling and advanced VFX
    pkgs.v4l-utils 
    # Audio Production
    pkgs.tenacity              # A modern, privacy-respecting fork of Audacity
    
    # Utilities & Downloader
    pkgs-unstable.yt-dlp       # Essential for content research/grabbing clips
    pkgs.handbrake             # Best tool for transcoding and compressing video
    pkgs.ffmpeg_7-full         # The "Swiss Army Knife" of media (Full version with codecs)
  ];
  # 2. Enable the Virtual Camera Kernel Module
  boot.extraModulePackages = with config.boot.kernelPackages; [
    v4l2loopback
  ];
  
  boot.kernelModules = [ "v4l2loopback" ];

  # 3. Configure the "Fake" Camera Device
  # exclusive_caps=1 is mandatory for Chromium/Zoom/Discord to see the camera
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=1 card_label="OBS Virtual Camera" exclusive_caps=1
  '';

  # 2. GPU Acceleration (Critical for DaVinci Resolve)
  # Note: DaVinci requires OpenCL or CUDA. 
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      # For AMD GPUs: 
      rocmPackages.clr.icd 
      # For Intel GPUs:
      # intel-compute-runtime 
    ];
  };

  # 3. Security/System Tweaks
  # Required for some OBS virtual camera features or high-performance audio
  security.polkit.enable = true;
  
  # Ensure unfree is allowed specifically for DaVinci Resolve
  nixpkgs.config.allowUnfree = true;
}