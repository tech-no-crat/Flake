{ config, pkgs, pkgs-unstable, lib, ... }:

let
  # 1. Define the pre-release package override
  sunshine-pre = pkgs-unstable.sunshine.overrideAttrs (oldAttrs: rec {
    version = "2026.214.30634";
    src = pkgs.fetchFromGitHub {
      owner = "LizardByte";
      repo = "Sunshine";
      rev = "v${version}";
      # Use a fake hash first; Nix will error and provide the correct one
      hash = lib.fakeHash; 
      fetchSubmodules = true;
    };

    # Pre-releases often require an updated UI build hash. 
    # If the build fails on 'npm', you may need to override this too:
    # ui = oldAttrs.ui.overrideAttrs (_: {
    #   npmDepsHash = lib.fakeHash;
    # });
  });
in
{
  # 2. Tell the system and the service to use the new package
  environment.systemPackages = [ sunshine-pre ];
  
  services.sunshine = {
    enable = true;
    package = sunshine-pre; # Critical: Ensures the service uses the pre-release
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true; 
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

  # 3. Rest of your existing config
  systemd.services.sunshine.enable = true;

  networking.firewall = {
    allowedTCPPorts = [ 47984 47989 47990 48010 ];
    allowedUDPPortRanges = [
      { from = 47998; to = 48000; }
      { from = 8000; to = 8010; }
    ];
  };
}
