{ config, pkgs, pkgs-unstable, ... }:

{
  # 1. Install the package (from Unstable as requested)
  environment.systemPackages = [
    pkgs-unstable.sunshine
  ];

  # 2. Service Configuration
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true; # This automatically opens standard Sunshine ports
    applications = {
      apps = [
        {
          name = "SteamBigPicture";
          detached = [ "setsid steam steam://open/bigpicture" ];
          auto-detach = "true";
          image-path = "steam.png";
        }
        {
          name = "Desktop";
          image-path = "desktop.png";
        }
      ];
    };
  };
  
  # 3. Systemd wrapper (moved from your original config)
  systemd.services.sunshine.enable = true;

  # 4. Manual Firewall Rules (Cleaned up from main config)
  # Note: services.sunshine.openFirewall handles most, but we keep your explicit ranges here to be safe.
  networking.firewall = {
    allowedTCPPorts = [ 47984 47989 47990 48010 ];
    allowedUDPPortRanges = [
      { from = 47998; to = 48000; }
      { from = 8000; to = 8010; }
    ];
  };
}
