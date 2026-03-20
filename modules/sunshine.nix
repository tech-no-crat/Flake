{ config, pkgs, pkgs-unstable, ... }:


{
  # 1. Force the service to use the unstable version
  services.sunshine = {
    enable = true;
    package = pkgs-unstable.sunshine; # This is the key line
    autoStart = true;
    capSysAdmin = true; # Required for keyboard/mouse/gamepad emulation
    openFirewall = true; # Automatically opens 47984, 47989, 47990, 48010 (TCP) & 47998-48000 (UDP)
    
    applications = {
      apps = [
        {
          name = "SteamBigPicture";
          detached = [ "setsid steam steam://open/bigpicture" ];
          auto-detach = true; # Fixed: must be a boolean, not a string
          image-path = "steam.png";
        }
        {
          name = "Desktop";
          image-path = "desktop.png";
        }
      ];
    };
  };

  # 2. Add the unstable package to your system environment for manual CLI access
  environment.systemPackages = [
    pkgs-unstable.sunshine
  ];
}

  # 3. Manual Firewall Rules (Only for your custom ranges)
  #networking.firewall = {
  #  allowedUDPPortRanges = [
  #    { from = 8000; to = 8010; }
  #  ];
  #};
  # AIGEN, don't know what this is
  # 4. Optional but Recommended: uinput rules for controllers
  # This ensures Sunshine has permission to create virtual input devices
  #boot.kernelModules = [ "uinput" ];
  #services.udev.extraRules = ''
  #  KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
  #'';
