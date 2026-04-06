# NixOS Configuration Cleanup Analysis

## Summary
Your configuration has **significant duplication** across system configs and home configs. The main issue is that `hosts/default/configuration.nix` is being used as a shared base but is **directly imported alongside host-specific configs**, causing dramatic duplication.

---

## 🔴 CRITICAL ISSUES

### Issue 1: `hosts/default/` Duplication in Flake
**Location:** `flake.nix` lines 44-45
```nix
modules = [
  ./hosts/nixos/configuration.nix
  ./hosts/default/configuration.nix  # ❌ LOADED WITH hosts/nixos/configuration.nix
  ...
]
```

**Problem:** Both `hosts/default/configuration.nix` and `hosts/nixos/configuration.nix` contain nearly **IDENTICAL** settings:
- Boot loader config (both `systemd-boot`)
- Graphics (both `hardware.graphics`)
- Networking (both `networkmanager`)
- Services (openssh, tailscale, resolved, printing, pipewire)
- User setup (identical shyam user)
- Desktop (GNOME, GDM)
- System packages
- Garbage collection
- Firefox, allowUnfree

**Recommendation:** Either:
1. **Option A (Recommended):** Delete `hosts/default/configuration.nix` and move its unique settings to modules
2. **Option B:** Use `hosts/default/` as the actual default and remove duplication from `hosts/nixos/`

---

### Issue 2: Surface Book Duplicate Configuration
**Locations:** `hosts/surface-book-{active,passive}/configuration.nix`

Both files contain **IDENTICAL** sections:
- Boot loader (systemd-boot, EFI)
- i18n/Localization (all 8 locale settings - **byte-for-byte identical**)
- Services (printing, tailscale, openssh, pipewire with `alsa.support32Bit`)
- Desktop (GNOME, GDM)
- Docker
- User setup (similar, docker group)
- 1Password config
- System packages (vim, wget, git)

**Differences:**
- `surface-book-active`: Has NVIDIA GPU config + Intel driver
- `surface-book-passive`: NVIDIA GPU config is **commented out**

**Recommendation:** Create `hosts/surface-book-common.nix` and extract shared settings

---

### Issue 3: Home Manager Configuration Not Used
**Files:**
- `home/default/home.nix` - **EXISTS BUT NOT IMPORTED IN FLAKE**
- `home/surface-book-active/home.nix` - Imported ✓
- `home/surface-book-passive/home.nix` - Imported ✓

**The problem:** `home/default/` should be the base, but it's orphaned. Meanwhile:
- `home/surface-book-active/home.nix` and `home/surface-book-passive/home.nix` have **IDENTICAL packages**:
  ```nix
  nextcloud-client
  moonlight-qt
  obsidian
  neovim
  nodejs_24
  ```

**Recommendation:** Use proper inheritance pattern:
```nix
home.packages = (import ../default/home.nix { inherit config pkgs pkgs-unstable; }).home.packages ++ [
  # device-specific packages
];
```

---

## 📋 DUPLICATION MATRIX

### System Configuration Duplicates

| Setting | hosts/default | hosts/nixos | surface-active | surface-passive |
|---------|---|---|---|---|
| `boot.loader.systemd-boot.enable` | ✓ | ✓ | ✓ | ✓ |
| `boot.loader.efi.canTouchEfiVariables` | ✓ | ✓ | ✓ | ✓ |
| `hardware.graphics.enable` | ✓ | ✓ | ✓ | ✓ |
| `networking.networkmanager.enable` | ✓ | ✓ | ✓ | ✓ |
| `networking.firewall.enable` | ✓ | ×  | × | × |
| `services.openssh.enable` | ✓ | ✓ | ✓ | ✓ |
| `services.tailscale.enable` | ✓ | ✓ | ✓ | ✓ |
| `services.resolved.enable` | ✓ | ✓ | × | × |
| `services.printing.enable` | ✓ | ✓ | ✓ | ✓ |
| `security.rtkit.enable` | ✓ | ✓ | ✓ | ✓ |
| `services.pipewire` | ✓ | ✓ | ✓ | ✓ |
| `services.desktopManager.gnome.enable` | ✓ | ✓ | ✓ | ✓ |
| `services.displayManager.gdm.enable` | ✓ | ✓ | ✓ | ✓ |
| `i18n.defaultLocale` | × | × | ✓ | ✓ |
| `programs.firefox.enable` | ✓ | ✓ | ✓ | ✓ |
| `programs._1password*` | × | × | ✓ | ✓ |
| `virtualisation.docker.enable` | × | × | ✓ | ✓ |

### Home Configuration Duplicates

| Package | default | surface-active | surface-passive |
|---------|---------|-----------------|-----------------|
| `nextcloud-client` | ✓ | ✓ | ✓ |
| `obsidian` | ✓ | ✓ | ✓ |
| `neovim` | ✓ | ✓ | ✓ |
| `git` (program) | ✓ | ✓ | ✓ |
| `home.username` | ✓ | ✓ | ✓ |
| `home.homeDirectory` | ✓ | ✓ | ✓ |
| `programs.direnv` | ✓ | × | × |
| `programs.git.settings` | ✓ | × | ✓ |

---

## 🛠️ IMPLEMENTATION ISSUES

### 1. **Incorrect Module Usage Pattern**
The `1password.nix` module exists but isn't consistently used:
- `hosts/nixos/configuration.nix` imports `../../modules/1password.nix` ✓
- `hosts/surface-book-active/configuration.nix` has 1password config **inline** ✗
- `hosts/surface-book-passive/configuration.nix` has 1password config **inline** ✗

**Fix:** Use the module instead of inlining

### 2. **Incomplete Surface Book Passive Setup**
`surface-book-passive` is missing:
- SSH authorized keys for user `shyam`
- This means the user can't SSH into this device

**Location:** [hosts/surface-book-passive/configuration.nix](hosts/surface-book-passive/configuration.nix#L133)

### 3. **Inconsistent Nix Settings**
- `hosts/default/configuration.nix`: Sets `nix.settings.trusted-users`, `experimental-features`, `secret-key-files`
- `hosts/surface-book-passive/configuration.nix`: Sets `nix.settings.*` values AND `experimental-features` at bottom
- These should be in ONE place

### 4. **Orphaned `hosts/default/` Purpose**
The file's intention is unclear:
- Is it a base/common config? (acted like one until Surface devices ignored it)
- Is it for the "default" host? (but it's not used that way in flake)
- Contains desktop setup (should be device-specific)

### 5. **xserver Configuration Duplication**
Different formulations of the same thing:
```nix
# hosts/nixos/configuration.nix
services.xserver = {
  enable = true;
  videoDrivers = [ "amdgpu" ];
  xkb = { layout = "us"; variant = ""; };
};

# hosts/surface-book-active/configuration.nix
services.xserver.videoDrivers = ["intel" "nvidia"];
services.xserver = {
  enable = true;
  displayManager.gdm.enable = true;  # Later redeclared below
  desktopManager.gnome.enable = true;
  xkb = { layout = "us"; variant = ""; };
};
# Then below:
services.displayManager.gdm.enable = true;  # ❌ DUPLICATE
services.desktopManager.gnome.enable = true;  # ❌ DUPLICATE
```

---

## ✅ CLEANUP PLAN (Recommended)

### Phase 1: Create Modular Structure
Create these new module files:

```
modules/
├── base.nix                    # Boot, graphics, firewall, basic services
├── gnome-desktop.nix           # GNOME, GDM, user setup, printing
├── nix-settings.nix            # Nix configuration, trusted users
├── localization.nix            # i18n settings for laptops
├── audio.nix                   # Pipewire setup (currently in gnome-desktop)
└── virtualization.nix          # Docker (from surface configs)
```

### Phase 2: Refactor Host Configuration
```
hosts/
├── common.nix                  # Shared settings across all hosts
├── nixos/configuration.nix     # nixos-specific (gaming, sunshine)
├── surface-book-common.nix     # Shared between active/passive
├── surface-book-active/configuration.nix     # NVIDIA only
└── surface-book-passive/configuration.nix    # Intel only
```

### Phase 3: Fix Home Manager
```nix
# home/default/home.nix
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
    direnv
  ];
  
  programs.direnv.enable = true;
  programs.git.enable = true;
  programs.git.settings = {
    user.name = "Tech-no-crat";
    user.email = "tech-no-crat2526@gmail.com";
  };
  
  home.stateVersion = "25.05";
}

# home/surface-book-active/home.nix
{ config, pkgs, pkgs-unstable, ... }:
let
  baseHome = import ../default/home.nix { inherit config pkgs pkgs-unstable; };
in baseHome // {
  home.packages = baseHome.home.packages ++ (with pkgs; [
    moonlight-qt
    nodejs_24
  ]);
}
```

---

## 📌 FILES TO DELETE/MARK FOR REMOVAL

1. **`hosts/default/configuration.nix`** - Contains ONLY duplicates of `hosts/nixos/configuration.nix`
   - Extract Nix settings → `modules/nix-settings.nix`
   - Delete file

2. **Inline 1password configs** in:
   - `hosts/surface-book-active/configuration.nix` (lines ~115-119)
   - `hosts/surface-book-passive/configuration.nix` (lines ~113-117)
   - Replace with: `../../modules/1password.nix` import

3. **Duplicate xserver blocks** in:
   - `hosts/surface-book-active/configuration.nix` (lines 68-77 and 98-100)
   - `hosts/surface-book-passive/configuration.nix` (lines ~59-63)

---

## 🎯 SIZE IMPACT
- Current shared config: **~400 lines of duplication**
- After cleanup: **~100 lines (modular, reusable)**
- **Reduction: ~75% duplication removed**

---

## 📝 Notes for Implementation

### hosts/default/configuration.nix - Reason for Duplication
Looking at your `flake.nix` (lines 44-45), this file is being loaded into the `nixos` configuration alongside `hosts/nixos/configuration.nix`. 

✓ **What you probably intended:** A base/common config that all hosts inherit from
✗ **What's happening:** Both files load independently, NixOS merges them all, causing duplicates

The proper NixOS flake pattern is:
- **Option 1 (Modules pattern)**: One `configuration.nix` per host, use `modules/` for shared logic
- **Option 2 (Common inheritance)**: Have a `common.nix` that's imported BY each host config

You're currently mixing these patterns incorrectly.

### Why Surface Devices Don't Use Modules
Your `surface-book-active` and `surface-book-passive` configs don't import the generalized modules (`gaming.nix`, `sunshine.nix`, etc.). This is likely because:
1. You created them with different design intent
2. They're laptop-focused, not desktop-focused
3. You haven't had a common place to share config yet

---

## Verification Checklist
After cleanup:
- [ ] `nixos-rebuild switch --flake .#nixos` ✓
- [ ] `nixos-rebuild switch --flake .#surface-book-active` ✓
- [ ] `nixos-rebuild switch --flake .#surface-book-passive` ✓
- [ ] GNOME desktop loads on all hosts
- [ ] SSH works on surface-book-passive (currently missing auth keys)

