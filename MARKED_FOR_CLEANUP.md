# Marked for Cleanup: Specific Code Sections

This document shows every section of code marked for removal, consolidation, or improvement with exact locations.

---

## FILE 1: `hosts/default/configuration.nix` - ENTIRE FILE MARKED FOR DELETION

**Status:** 🔴 DELETE AFTER EXTRACTING

**Reason:** This file is an attempt at a "common base" but is implemented incorrectly. It's imported alongside `hosts/nixos/configuration.nix` in the flake, causing duplication. Proper solution: extract to modules and delete this file.

**Extraction Map:**

```nix
# ❌ DELETE THESE SECTIONS - EXTRACT TO modules/nix-settings.nix
nix.settings = {
  trusted-users = [ "root" "shyam" ];
  experimental-features = [ "nix-command" "flakes" ];
  secret-key-files = [ "/home/shyam/.ssh/id_ed25519"];
};

# ❌ DELETE THESE SECTIONS - EXTRACT TO modules/base.nix
boot.loader.systemd-boot.enable = true;
boot.loader.efi.canTouchEfiVariables = true;
hardware.graphics = { ... };
networking.networkmanager.enable = true;
networking.firewall.* = ...;
services.openssh.enable = true;
services.tailscale.enable = true;
services.resolved.enable = true;
networking.useNetworkd = false;
services.printing.enable = true;
services.printing.drivers = [ ... ];
programs.firefox.enable = true;
nixpkgs.config.allowUnfree = true;
nix.gc = { ... };

# ❌ DELETE THESE SECTIONS - EXTRACT TO modules/gnome.nix
services.desktopManager.gnome.enable = true;
services.displayManager.gdm.enable = true;
services.displayManager.autoLogin.enable = true;
services.displayManager.autoLogin.user = "shyam";
security.rtkit.enable = true;
services.pipewire = { ... };
users.users.shyam = { ... };

# ✓ KEEP - unique to this file (but delete file anyway)
system.stateVersion = "25.05";
```

**Action:** After modules are created and imported into `hosts/nixos/configuration.nix`, delete this entire file.

---

## FILE 2: `hosts/nixos/configuration.nix` - CONSOLIDATION

### Section A: Module Imports (No change needed)
✓ Already imports modules correctly

### Section B: The `hosts/default/configuration.nix` import problem (Line ~44 in flake)
**In flake.nix - MARKED FOR REMOVAL:**
```nix
modules = [
  ./hosts/nixos/configuration.nix
  ./hosts/default/configuration.nix          ← ❌ DELETE THIS LINE FROM FLAKE
  home-manager.nixosModules.home-manager
  ...
];
```

**Action:** Remove this import from flake.nix after modules are created

### After Cleanup: Modified imports section
```nix
imports = [
  ./hardware-configuration.nix
  ../../modules/nix-settings.nix    # ← ADD
  ../../modules/base.nix             # ← ADD
  ../../modules/gnome.nix            # ← ADD
  ../../modules/audio.nix            # ← ADD (pipewire extracted)
  ../../modules/sunshine.nix
  ../../modules/gaming.nix
  ../../modules/multimedia.nix
  ../../modules/1password.nix
];
```

---

## FILE 3: `hosts/surface-book-active/configuration.nix` - MARKED SECTIONS

### Section A: Duplicate GDM/GNOME Declaration (Lines ~68-77 AND 98-100)

**Part 1 - Lines ~68-77 (services.xserver block):**
```nix
services.xserver = {
  enable = true;
  displayManager.gdm.enable = true;        ← ⚠️ REDUNDANT (declared again below)
  desktopManager.gnome.enable = true;      ← ⚠️ REDUNDANT (declared again below)
  xkb.layout = "us";
  xkb.variant = "";
};
```

**Part 2 - Lines ~98-100 (duplicate declarations):**
```nix
# for >25.11
services.displayManager.gdm.enable = true;   ← ❌ REMOVE (already in services.xserver above)
services.desktopManager.gnome.enable = true; ← ❌ REMOVE (already in services.xserver above)
```

**Fix:** Consolidate to single block:
```nix
services.xserver = {
  enable = true;
  videoDrivers = ["intel" "nvidia"];
  displayManager.gdm.enable = true;
  desktopManager.gnome.enable = true;
  xkb.layout = "us";
  xkb.variant = "";
};
# DELETE the duplicate declarations below this block
```

### Section B: Inline 1Password Configuration (Lines ~115-119)

**Current code - MARKED FOR REMOVAL:**
```nix
  # 1Password (System-level integration for Polkit)
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "shyam" ];
  };
```

**Action:** 
1. ❌ DELETE these lines
2. ✓ ADD to imports: `../../modules/1password.nix`

**Reason:** `modules/1password.nix` already exists and contains identical config

---

## FILE 4: `hosts/surface-book-passive/configuration.nix` - MULTIPLE MARKED SECTIONS

### Section A: Dead Code - Commented Out nvidia Block (Lines ~54-83)

**Status:** 🔴 HIGH PRIORITY REMOVAL

**Current code - 30 LINES OF DEAD CODE:**
```nix
  #hardware.nvidia = {
    # Modesetting is required
  #  modesetting.enable = true;
    
    # Enable the NVIDIA settings menu
  #  nvidiaSettings = true;

    # Use the open source kernel module (Turing+ GPUs)
   # open = true;

    # Use stable driver
    #package = config.boot.kernelPackages.nvidiaPackages.stable;

    # PRIME configuration
    #prime = {
      # Use "offload" (recommended for laptops) or "sync"
    #  offload = {
    #    enable = true;
    #    enableOffloadCmd = true;
    #  };
      
      # !!! ADJUST THESE BUS IDs !!!
    #  intelBusId = "PCI:0:2:0";
    #  nvidiaBusId = "PCI:1:0:0";
    #};

    # Power management (fine-grained is experimental, disable if it causes issues)
    #powerManagement.enable = false;
    #powerManagement.finegrained = false;
  #};
```

**Action:** ❌ DELETE ALL 30 LINES

**Reason:** 
- This device doesn't have NVIDIA (only Intel iGPU)
- Dead code clutters configuration
- If you ever want NVIDIA support, it's in `surface-book-active/` as reference

---

### Section B: Inline 1Password Configuration (Lines ~113-117)

**Current code - MARKED FOR REMOVAL:**
```nix
  # 1Password (System-level integration for Polkit)
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "shyam" ];
  };
```

**Action:**
1. ❌ DELETE these lines
2. ✓ ADD to imports: `../../modules/1password.nix`

---

### Section C: CRITICAL - Missing SSH Authorized Keys (User section)

**Current code - MARKED FOR ADDITION:**
```nix
  users.users.shyam = {
    isNormalUser = true;
    description = "Shyam Shukla";
    # Added "docker" group so you don't need sudo for docker commands
    extraGroups = [ "networkmanager" "wheel" "docker" "surface-control"];
    # ❌ MISSING: openssh.authorizedKeys.keys = [ ... ];
  };
```

**Status:** 🔴 HIGH PRIORITY - This user cannot SSH into this device!

**Fix - Add after extraGroups:**
```nix
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINmAV4/B3jWOIJPgexSzCDDcK1lb+fD2tzA0i+Lxxgs3 shyam@clerics.ca"
    ];
```

**Copy from:** `hosts/surface-book-active/configuration.nix` (same key) or `hosts/nixos/configuration.nix`

---

### Section D: Duplicate i18n/Localization Settings (Lines ~43-62)

**Status:** ⚠️ MEDIUM - Shared with surface-book-active

**Should be moved to `modules/surface-common.nix`**

```nix
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
```

**Action:** After creating `modules/surface-common.nix`, import it and delete these lines from both surface configs

---

### Section E: Duplicate Pipewire Configuration (Lines ~95-101)

**Status:** ⚠️ MEDIUM - Identical in both surface configs

```nix
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
```

**Should be:** Moved to common audio module or `modules/surface-common.nix`

---

## FILE 5: `home/default/home.nix` - MARKED AS ORPHANED

**Status:** ⚠️ MARKED AS UNUSED BUT CONTAINS GOOD BASE CONFIG

**Current state:**
- File exists but is NOT imported in flake.nix
- Similar packages declared in `home/surface-book-{active,passive}/home.nix` (duplication)
- `programs.direnv` only in default (missing from surface)
- `programs.git` settings in default but different declarationin surface-book-passive

**Cleanup action:**
1. ✓ Keep this file as the BASE home configuration
2. ✓ Modify flake.nix to use it as default
3. ✓ Have `home/surface-book-{active,passive}/` IMPORT and EXTEND it

**After cleanup structure:**
```nix
# home/default/home.nix (SHARED BASE)
{ config, pkgs, pkgs-unstable, ... }:
{
  home.username = "shyam";
  home.homeDirectory = "/home/shyam";
  nixpkgs.config.allowUnfree = true;
  
  home.packages = with pkgs; [
    nextcloud-client
    obsidian
    neovim
    git
  ];
  
  programs.direnv.enable = true;
  programs.git.enable = true;
  programs.git.settings = {
    user.name = "Tech-no-crat";
    user.email = "tech-no-crat2526@gmail.com";
  };
  
  home.stateVersion = "25.05";
}

# home/surface-book-active/home.nix (EXTENDS BASE)
{ config, pkgs, pkgs-unstable, ... }:
{
  imports = [ ../default/home.nix ];
  # Add only mobile-specific packages
  home.packages = (import ../default/home.nix { inherit config pkgs pkgs-unstable; }).home.packages ++ (with pkgs; [
    moonlight-qt
    nodejs_24
  ]);
}
```

---

## FILE 6: `modules/multimedia.nix` - COMMENT ERROR

**Lines:** 1-2 (header comment)

**Current code:**
```nix
# modules/creative.nix  ← ❌ WRONG - File is named multimedia.nix
{ config, pkgs, pkgs-unstable, ... }:
```

**Fix:**
Change to:
```nix
# modules/multimedia.nix
{ config, pkgs, pkgs-unstable, ... }:
```

**Or alternatively:** Rename file from `multimedia.nix` to `creative.nix` and update import in `hosts/nixos/configuration.nix`

---

## FILE 7: `flake.nix` - MARKED MODIFICATIONS

### Section A: Remove duplicate import for nixos config (Lines ~44-45)

**Current:**
```nix
nixos = nixpkgs-unstable.lib.nixosSystem {
  inherit system;
  specialArgs = { inherit inputs pkgs-unstable; };
  modules = [
    ./hosts/nixos/configuration.nix
    ./hosts/default/configuration.nix          ← ❌ DELETE THIS LINE
    home-manager.nixosModules.home-manager
    {
      home-manager.useUserPackages = true;
      home-manager.extraSpecialArgs = { inherit inputs pkgs-unstable; };
      home-manager.users.shyam = import ./home/nixos/home.nix;
    }
  ];
};
```

**After cleanup:**
```nix
nixos = nixpkgs-unstable.lib.nixosSystem {
  inherit system;
  specialArgs = { inherit inputs pkgs-unstable; };
  modules = [
    ./hosts/nixos/configuration.nix   # ← Now contains all imports needed
    home-manager.nixosModules.home-manager
    {
      home-manager.useUserPackages = true;
      home-manager.extraSpecialArgs = { inherit inputs pkgs-unstable; };
      home-manager.users.shyam = import ./home/default/home.nix;  # Changed to use default
    }
  ];
};
```

---

## Cleanup Checklist

- [ ] Create `modules/base.nix` (extract from hosts/default)
- [ ] Create `modules/gnome.nix` (extract from hosts/default + surface configs)
- [ ] Create `modules/nix-settings.nix` (extract from hosts/default + surface-passive)
- [ ] Create `modules/audio.nix` (extract pipewire configs)
- [ ] Create `modules/surface-common.nix` (shared surface setup)
- [ ] Add `modules/nvidia.nix` (optional - for surface-active specific)
- [ ] Update `hosts/nixos/configuration.nix` to import new modules
- [ ] Update `hosts/surface-book-active/configuration.nix` to import modules + remove 1password inline + fix xserver duplication
- [ ] Update `hosts/surface-book-passive/configuration.nix` to import modules + add SSH keys + remove dead code
- [ ] Update `flake.nix` to remove `./hosts/default/configuration.nix` import
- [ ] Update `flake.nix` to use `./home/default/home.nix` for all users
- [ ] Update `home/surface-book-{active,passive}` to inherit from default
- [ ] Fix `modules/multimedia.nix` header comment
- [ ] Delete `hosts/default/configuration.nix`
- [ ] Test rebuild: `nixos-rebuild switch --flake .#nixos`
- [ ] Test rebuild: `nixos-rebuild switch --flake .#surface-book-active`
- [ ] Test rebuild: `nixos-rebuild switch --flake .#surface-book-passive`

