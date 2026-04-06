# Proposed Module Structure - Reference Implementation

This document provides template code for the new modular structure to replace the duplicated configurations.

---

## New Module Files to Create

### 1. `modules/base.nix` - Common System Foundation

Extract from `hosts/default/configuration.nix`

```nix
# modules/base.nix
# Common configuration shared by all NixOS hosts
{ config, pkgs, ... }:

{
  # --- Boot & Hardware ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Graphics - baseline (host-specific configs can add more)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # --- Networking ---
  networking.networkmanager.enable = true;
  
  # Firewall: Keep SSH & WoL open
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ];
  networking.firewall.allowedUDPPorts = [ 9 ];

  # --- Services ---
  services.openssh.enable = true;
  services.tailscale.enable = true;
  services.resolved.enable = true;
  networking.useNetworkd = false;

  # --- System Packages ---
  environment.systemPackages = with pkgs; [
    vim
    wget
  ];

  programs.firefox.enable = true;
  nixpkgs.config.allowUnfree = true;

  # --- Garbage Collection ---
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
}
```

**Usage in host config:**
```nix
imports = [
  ../../modules/base.nix
];
```

---

### 2. `modules/gnome.nix` - GNOME Desktop Environment

Extract from `hosts/default/configuration.nix` + duplicates from surface configs

```nix
# modules/gnome.nix
# GNOME desktop environment configuration
{ config, pkgs, ... }:

{
  # --- Desktop ---
  services.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "shyam";

  # --- Audio & Printing ---
  services.printing.enable = true;
  services.printing.drivers = [
    pkgs.splix
    pkgs.samsung-unified-linux-driver
  ];

  # --- User Setup ---
  users.users.shyam = {
    isNormalUser = true;
    description = "shyam";
    extraGroups = [ "networkmanager" "wheel" "uinput" "input" "video" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINmAV4/B3jWOIJPgexSzCDDcK1lb+fD2tzA0i+Lxxgs3 shyam@clerics.ca"
    ];
  };
}
```

**Usage in host config:**
```nix
imports = [
  ../../modules/gnome.nix
];
```

---

### 3. `modules/audio.nix` - PipeWire Audio System

Extract from `hosts/default/configuration.nix` + both surface configs

```nix
# modules/audio.nix
# Audio system configuration (PipeWire)
{ ... }:

{
  # Audio setup
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
}
```

**Optional expansion for laptops (where alsa.support32Bit is needed):**
```nix
# modules/audio-laptop.nix - for Surface devices
{ ... }:

{
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
}
```

---

### 4. `modules/nix-settings.nix` - Nix Configuration

Extract from `hosts/default/configuration.nix` + `hosts/surface-book-passive/configuration.nix`

```nix
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

  # Optional: Per-host secret keys can be added by each host config
  # nix.settings.secret-key-files = [ "/home/shyam/.ssh/id_ed25519" ];
  # nix.settings.trusted-public-keys = [ ... ];
}
```

---

### 5. `modules/surface-common.nix` - Surface Laptop Shared Settings

Extract from both `surface-book-active` and `surface-book-passive`

```nix
# modules/surface-common.nix
# Shared configuration for Microsoft Surface devices
{ ... }:

{
  # --- Hardware support for Surface devices ---
  # (Handled in flake.nix via nixos-hardware module)

  # --- Localization (same for both Surface laptops) ---
  time.timeZone = "America/New_York";
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

  # --- Virtualization ---
  virtualisation.docker.enable = true;

  # --- User Setup (Surface-specific) ---
  users.users.shyam = {
    isNormalUser = true;
    description = "Shyam Shukla";
    extraGroups = [ "networkmanager" "wheel" "docker" "surface-control" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINmAV4/B3jWOIJPgexSzCDDcK1lb+fD2tzA0i+Lxxgs3 shyam@clerics.ca"
    ];
  };

  # System packages (minimal for laptops)
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
  ];

  programs.firefox.enable = true;
  nixpkgs.config.allowUnfree = true;
}
```

---

### 6. `modules/nvidia-surface.nix` - NVIDIA GPU for Surface Book Active

Create new for surface-book-active specific config

```nix
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
```

---

### 7. `modules/intel-surface.nix` - Intel iGPU for Surface Book Passive

Create new for surface-book-passive specific config

```nix
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
```

---

## Updated Host Configuration Files

### `hosts/nixos/configuration.nix` - UPDATED

```nix
{ config, pkgs, pkgs-unstable, ... }:

{
  imports = [
    ./hardware-configuration.nix
    # Shared modules
    ../../modules/nix-settings.nix
    ../../modules/base.nix
    ../../modules/gnome.nix
    ../../modules/audio.nix
    # Host-specific modules
    ../../modules/sunshine.nix
    ../../modules/gaming.nix
    ../../modules/multimedia.nix
    ../../modules/1password.nix
  ];

  # --- Host-specific configuration ---
  networking.hostName = "nixos";

  # Desktop-specific hardware setup
  boot.initrd.kernelModules = [ "uinput" "amdgpu" ];
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.extraModprobeConfig = "options amdgpu ppfeaturemask=0xffffffff\n";
  boot.kernel.sysctl = {
    "kernel.perf_cpu_time_max_percent" = 50;
    "vm.max_map_count" = 2147483642;
  };

  # Backup drive
  fileSystems."/mnt/backup-drive" = {
    device = "/dev/disk/by-uuid/458e1884-3102-4d69-b005-9e0291cbd23d";
    fsType = "ext4";
    options = [ "nofail" "defaults" ];
  };

  # Desktop GPU setup
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      rocmPackages.clr.icd
      libva
    ];
  };

  networking.interfaces.eno1.wakeOnLan.enable = true;

  # Desktop X Server setup
  services.xserver = {
    enable = true;
    videoDrivers = [ "amdgpu" ];
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  services.lact.enable = true;
  services.udev.extraRules = ''
    KERNEL=="uinput", MODE="0660", GROUP="input", OPTIONS+="static_node=uinput"
  '';

  # Borg backup user
  users.users.borgbackup = {
    isNormalUser = true;
    home = "/var/lib/borgbackup";
    createHome = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDutRxlBfz7idOa6EN06bDP9bxL8sTGQ0Z6z90/EnBjz"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICARgR3Z/4HGCgxCoIeAP5F2Owfh1x9wAWvilSia7E3J shyamshukla@Shyams-Mac-mini"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /mnt/backup-drive/nextcloud-borg-backup-repo 0700 borgbackup borgbackup -"
  ];

  # Extended system packages (desktop-specific)
  environment.systemPackages = with pkgs; [
    mesa-demos
    vulkan-tools
    clinfo
    libva-utils
    lact
    amdgpu_top
    nvtopPackages.amd
    htop
    btop
    powertop
    lm_sensors
    borgbackup
  ];

  programs.direnv.enable = true;

  system.stateVersion = "25.05";
}
```

### `hosts/surface-book-active/configuration.nix` - UPDATED

```nix
{ config, pkgs, pkgs-unstable, ... }:

{
  imports = [
    ./hardware-configuration.nix
    # Shared modules
    ../../modules/nix-settings.nix
    ../../modules/base.nix
    ../../modules/audio-laptop.nix  # Use laptop variant with alsa.support32Bit
    ../../modules/surface-common.nix
    # GPU-specific
    ../../modules/nvidia-surface.nix
    # Applications
    ../../modules/1password.nix
  ];

  # --- Surface-specific hardware ---
  networking.hostName = "surface-book-active";
  hardware.microsoft-surface.kernelVersion = "stable";

  system.stateVersion = "25.05";
}
```

### `hosts/surface-book-passive/configuration.nix` - UPDATED

```nix
{ config, pkgs, pkgs-unstable, ... }:

{
  imports = [
    ./hardware-configuration.nix
    # Shared modules
    ../../modules/nix-settings.nix
    ../../modules/base.nix
    ../../modules/audio-laptop.nix  # Use laptop variant with alsa.support32Bit
    ../../modules/surface-common.nix
    # GPU-specific
    ../../modules/intel-surface.nix
    # Applications
    ../../modules/1password.nix
  ];

  # --- Surface-specific hardware ---
  networking.hostName = "surface-book-passive";
  hardware.microsoft-surface.kernelVersion = "stable";

  # Cache configuration (unique to this host)
  nix.settings.secret-key-files = [ "/home/shyam/.config/nix/secret-key" ];
  nix.settings.trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypf7apZDa8T7nheRbMjGQB7QS0="
    "nixos:ja/7KdhK9zIWJCUM+FQCHNgUqNExRTNWSDXIkS++ohw="
    "nixos:fMkk4PAA/Ep6aEEL+zDT4Lv3jalYk0Yl+vJ2cho0+wL4DJElp7hCwOh0fVz5CRrqrVn+oIUZEuegMJSgn8wcDw=="
  ];
  nix.settings.require-sigs = false;

  system.stateVersion = "25.05";
}
```

---

## Updated Home Configuration Files

### `home/default/home.nix` - KEPT AS BASE

```nix
{ config, pkgs, pkgs-unstable, ... }:

{
  home.username = "shyam";
  home.homeDirectory = "/home/shyam";
  
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # --- Shared User Packages ---
  home.packages = with pkgs; [
    # Communication / Sync
    nextcloud-client
    
    # Productivity
    obsidian
    thunderbird
    
    # Development / Tools
    git
    ethtool
    iw
    neovim
    
    # Unstable packages
    pkgs-unstable.discord
    pkgs-unstable.vscode
  ];

  # --- Programs ---
  programs.direnv.enable = true;
  programs.git.enable = true;
  programs.git.settings = {
    user.name = "Tech-no-crat";
    user.email = "tech-no-crat2526@gmail.com";
  };

  home.stateVersion = "25.05";
}
```

### `home/surface-book-active/home.nix` - INHERITS FROM DEFAULT

```nix
{ config, pkgs, pkgs-unstable, ... }:

let
  base = import ../default/home.nix { inherit config pkgs pkgs-unstable; };
in
base // {
  home.packages = base.home.packages ++ (with pkgs; [
    # Mobile-specific packages
    moonlight-qt
    nodejs_24
  ]);
}
```

### `home/surface-book-passive/home.nix` - INHERITS FROM DEFAULT

```nix
{ config, pkgs, pkgs-unstable, ... }:

let
  base = import ../default/home.nix { inherit config pkgs pkgs-unstable; };
in
base // {
  home.packages = base.home.packages ++ (with pkgs; [
    # Mobile-specific packages
    moonlight-qt
    nodejs_24
    _1password-cli
  ]);
}
```

---

## Updated `flake.nix` Snippet

**Changes:**
1. Remove `./hosts/default/configuration.nix` from modules
2. Change home imports to use `./home/default/home.nix`

```nix
nixosConfigurations = {
  # Your Desktop (Existing)
  nixos = nixpkgs-unstable.lib.nixosSystem {
    inherit system;
    specialArgs = { inherit inputs pkgs-unstable; };
    modules = [
      ./hosts/nixos/configuration.nix            # ← Handles all imports
      # ./hosts/default/configuration.nix        # ← DELETE THIS LINE
      home-manager.nixosModules.home-manager
      {
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = { inherit inputs pkgs-unstable; };
        home-manager.users.shyam = import ./home/default/home.nix;
      }
    ];
  };

  surface-book-active = nixpkgs-unstable.lib.nixosSystem {
    inherit system;
    specialArgs = { inherit inputs pkgs-unstable; };
    modules = [
      nixos-hardware.nixosModules.microsoft-surface-common
      ./hosts/surface-book-active/configuration.nix
      home-manager.nixosModules.home-manager
      {
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = { inherit inputs pkgs-unstable; };
        home-manager.users.shyam = import ./home/surface-book-active/home.nix;
      }
    ];
  };

  surface-book-passive = nixpkgs-unstable.lib.nixosSystem {
    inherit system;
    specialArgs = { inherit inputs pkgs-unstable; };
    modules = [
      nixos-hardware.nixosModules.microsoft-surface-common
      ./hosts/surface-book-passive/configuration.nix
      home-manager.nixosModules.home-manager
      {
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = { inherit inputs pkgs-unstable; };
        home-manager.users.shyam = import ./home/surface-book-passive/home.nix;
      }
    ];
  };
};
```

---

## Final File Structure

After refactoring:

```
flakes/
├── flake.nix
├── modules/
│   ├── 1password.nix          (existing - unchanged)
│   ├── gaming.nix             (existing - unchanged)
│   ├── multimedia.nix         (existing - fix comment)
│   ├── nctalk.nix             (existing - unchanged)
│   ├── plex.nix               (existing - unchanged)
│   ├── sunshine.nix           (existing - unchanged)
│   ├── base.nix               (NEW - common foundation)
│   ├── gnome.nix              (NEW - desktop environment)
│   ├── audio.nix              (NEW - audio system)
│   ├── audio-laptop.nix       (NEW - laptop audio variant)
│   ├── nix-settings.nix       (NEW - nix configuration)
│   ├── surface-common.nix     (NEW - surface laptop shared)
│   ├── nvidia-surface.nix     (NEW - nvidia for active)
│   └── intel-surface.nix      (NEW - intel for passive)
├── hosts/
│   ├── nixos/
│   │   ├── configuration.nix  (REFACTORED - imports modules)
│   │   └── hardware-configuration.nix
│   ├── surface-book-active/
│   │   ├── configuration.nix  (REFACTORED - imports modules)
│   │   └── hardware-configuration.nix
│   ├── surface-book-passive/
│   │   ├── configuration.nix  (REFACTORED - imports modules)
│   │   └── hardware-configuration.nix
│   └── default/
│       └── configuration.nix  (DELETED)
├── home/
│   ├── default/
│   │   └── home.nix           (KEPT - as base)
│   ├── nixos/
│   │   └── home.nix           (unchanged - not used)
│   ├── surface-book-active/
│   │   └── home.nix           (REFACTORED - inherits from default)
│   └── surface-book-passive/
│       └── home.nix           (REFACTORED - inherits from default)
├── CLEANUP_ANALYSIS.md        (NEW - this analysis)
├── IMPLEMENTATION_FEEDBACK.md (NEW - detailed feedback)
├── MARKED_FOR_CLEANUP.md      (NEW - specific sections)
├── README.md
└── result
```

---

## Verification After Implementation

```bash
# Test compiling all configurations
nix flake check

# Test nixos config builds without errors
nixos-rebuild build --flake .#nixos

# Test surface-active config
nixos-rebuild build --flake .#surface-book-active

# Test surface-passive config
nixos-rebuild build --flake .#surface-book-passive

# Actually switch to new config (do this on one machine first)
nixos-rebuild switch --flake .#nixos

# Check for syntax errors
nix eval --file flake.nix
```

