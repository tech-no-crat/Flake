# Modular NixOS Configuration

A clean, composable NixOS setup using flakes with an inheritance-based architecture. Common configurations live in `default`, while host-specific configs import and extend them. No duplication.

---

## Architecture Overview

| **Beginner** | **Intermediate** | **Advanced** |
|---|---|---|
| **What is this?**<br/>This repo organizes your NixOS settings into reusable pieces. Instead of copying the same settings across files, we write them once and reuse them. | **Design Pattern**<br/>Uses inheritance-via-imports. `default` files contain shared settings; host-specific files import defaults and add their own settings. Eliminates ~400 lines of duplication. | **Module Composition**<br/>Leverages NixOS module system with explicit import chains. Base modules provide common services (networking, PipeWire, GNOME). Host configs compose via import + attribute merging. Home-manager users extend base packages. |
| **File Structure**<br/>Files are organized by purpose:<br/>- `hosts/` — system configs<br/>- `home/` — user packages<br/>- `modules/` — reusable pieces<br/>- `flake.nix` — entry point | **Inheritance Chain**<br/>`hosts/nixos/` → imports `../default/` (gets common boot, graphics, networking) → adds desktop-specific modules (audio, gaming, sunshine).<br/><br/>`home/nixos/` → imports `../default/` (gets common packages) → adds desktop apps (discord, vscode) | **Flake Outputs**<br/>`nixosConfigurations` declare three systems (nixos, surface-book-active, surface-book-passive) with specialArgs passing pkgs-unstable and inputs. Home-manager modules layered via extraSpecialArgs. System stateVersion per host. |
| **How it works in practice**<br/>You edit `hosts/your-machine/configuration.nix`. It's short because it imports from `../default/` (which has boot, graphics, networking) and only adds machine-specific stuff. | **Adding a new host**<br/>1. Create `hosts/your-machine/configuration.nix`<br/>2. Add `imports = [ ../default/configuration.nix ];`<br/>3. Add only your host-specific settings (hostname, GPU driver, etc.)<br/>4. Define corresponding `home/your-machine/home.nix` | **Adding a new module**<br/>Create `modules/my-feature.nix` with standard NixOS module format: `{ config, pkgs, ... }: { options = {...}; config = {...}; }`<br/>Import in host config.<br/>No side effects; pure data transformations. |

---

## Directory Structure

```
flake.nix                           # Entry point; declares three nixosConfigurations
├── hosts/
│   ├── default/
│   │   └── configuration.nix       # ← Common baseline (boot, graphics, networking, services)
│   ├── nixos/
│   │   ├── configuration.nix       # Imports ../default + adds desktop modules
│   │   └── hardware-configuration.nix
│   ├── surface-book-active/
│   │   ├── configuration.nix       # Imports ../default + laptop + NVIDIA modules
│   │   └── hardware-configuration.nix
│   └── surface-book-passive/
│       ├── configuration.nix       # Imports ../default + laptop + Intel modules
│       └── hardware-configuration.nix
├── home/
│   ├── default/
│   │   └── home.nix                # ← Common packages (git, neovim, direnv, obsidian)
│   ├── nixos/
│   │   └── home.nix                # Imports ../default + adds desktop packages
│   ├── surface-book-active/
│   │   └── home.nix                # Imports ../default + adds laptop packages
│   └── surface-book-passive/
│       └── home.nix                # Imports ../default + adds laptop packages
└── modules/                        # Reusable NixOS modules
    ├── base.nix                    # Boot, graphics, networking, Firefox, Vim, Wget
    ├── gnome.nix                   # GNOME desktop, GDM, user setup
    ├── audio.nix                   # PipeWire (desktop, no 32-bit)
    ├── audio-laptop.nix            # PipeWire (laptop, with 32-bit)
    ├── nix-settings.nix            # Nix config (trusted-users, experimental-features)
    ├── surface-common.nix          # Surface hardware (timezone, localization, docker)
    ├── nvidia-surface.nix          # NVIDIA GPU with PRIME
    ├── intel-surface.nix           # Intel iGPU only
    ├── sunshine.nix                # Remote desktop streaming
    ├── gaming.nix                  # Steam, proton, DXVK
    ├── multimedia.nix              # GIMP, Blender, OBS
    ├── 1password.nix               # 1Password CLI and GUI
    └── plex.nix                    # Plex media server
```

---

## Inheritance Diagram

### System Configuration (hosts/)

```
┌─────────────────────────────────────────────────────────────────┐
│                    hosts/default/configuration.nix              │
│                                                                 │
│  imports = [                                                    │
│    ../../modules/nix-settings.nix                               │
│    ../../modules/base.nix                                       │
│    ../../modules/gnome.nix                                      │
│  ];                                                             │
│  # Common boot, graphics, networking, GNOME desktop            │
└─────────────────────────────────────────────────────────────────┘
  ▲                           ▲                         ▲
  │                           │                         │
  │ imported by              │ imported by             │ imported by
  │                           │                         │
┌─────────────────────┐  ┌──────────────────────┐  ┌──────────────────────┐
│ hosts/nixos/        │  │ hosts/surface-       │  │ hosts/surface-       │
│ configuration.nix   │  │ book-active/config   │  │ book-passive/config  │
├─────────────────────┤  ├──────────────────────┤  ├──────────────────────┤
│ imports = [         │  │ imports = [          │  │ imports = [          │
│  ../default/        │  │  ../default/         │  │  ../default/         │
│  ../../modules/     │  │  ../../modules/      │  │  ../../modules/      │
│    audio.nix        │  │    audio-laptop.nix  │  │    audio-laptop.nix  │
│  ... + desktop      │  │    surface-common    │  │    surface-common    │
│    modules          │  │    nvidia-surface    │  │    intel-surface     │
│ ];                  │  │ ];                   │  │ ];                   │
│                     │  │                      │  │ networking.hostName  │
│ networking.hostName │  │ networking.hostName  │  │   = "surface-book-   │
│   = "nixos";        │  │   = "surface-book-   │  │     passive";        │
│                     │  │   active";           │  │                      │
│ +Desktop specific:  │  │ +Laptop specific:    │  │ +Intel iGPU config   │
│  - gaming.nix       │  │  - sony hdmi audio   │  │ +SSH key setup       │
│  - sunshine.nix     │  │  - nvidia settings   │  │                      │
│  - multimedia.nix   │  │  - battery mgmt      │  └──────────────────────┘
└─────────────────────┘  └──────────────────────┘
```

### Home Manager Configuration (home/)

```
┌────────────────────────────────────────────────────────────┐
│             home/default/home.nix                          │
│                                                            │
│  { pkgs-unstable, ... }                                    │
│  {                                                         │
│    home.packages = [                                       │
│      pkgs.nextcloud-client  # Truly common to all hosts    │
│      pkgs.obsidian                                         │
│      pkgs.git                                              │
│      pkgs.neovim                                           │
│      pkgs.direnv                                           │
│    ];                                                      │
│    home.stateVersion = "25.11";                            │
│  }                                                         │
└────────────────────────────────────────────────────────────┘
  ▲                   ▲                       ▲
  │                   │                       │
  │ inherited by      │ inherited by          │ inherited by
  │                   │                       │
┌────────────────┐ ┌──────────────────┐ ┌──────────────────┐
│ home/nixos/    │ │ home/surface-    │ │ home/surface-    │
│ home.nix       │ │ book-active/     │ │ book-passive/    │
├────────────────┤ │ home.nix         │ │ home.nix         │
│ imports = [    │ ├──────────────────┤ ├──────────────────┤
│  ../default    │ │ imports = [      │ │ imports = [      │
│ ];             │ │  ../default      │ │  ../default      │
│ home.packages  │ │ ];               │ │ ];               │
│   ++ [         │ │ home.packages    │ │ home.packages    │
│   thunderbird  │ │   ++ [           │ │   ++ [           │
│   discord      │ │   moonlight-qt   │ │   moonlight-qt   │
│   vscode       │ │   nodejs_24      │ │   nodejs_24      │
│   ethtool      │ │ ];               │ │   _1password-cli │
│   iw           │ └──────────────────┘ │ ];               │
│ ];             │                       └──────────────────┘
└────────────────┘
```

---

## Quick Start: Adapt for Your Machine

### Beginner Path

1. **Clone and navigate:**
   ```bash
   cd ~ && git clone https://github.com/tech-no-crat/Flake.git && cd Flake
   ```

2. **Identify your hostname:**
   ```bash
   hostname
   ```

3. **Copy your hardware config:**
   ```bash
   sudo cp /etc/nixos/hardware-configuration.nix hosts/default/
   ```

4. **Edit `flake.nix`:**
   - Find `nixos = nixpkgs-unstable.lib.nixosSystem` (around line 39)
   - If renaming: change the key from `nixos` to your hostname
   - Delete the `surface-book-active` and `surface-book-passive` configurations if you only need one system

5. **Edit `hosts/default/configuration.nix`:**
   - Change `networking.hostName` to match your hostname
   - Comment/uncomment modules you want (gnome desktop, audio, gaming, etc.)
   - Most edits are straightforward: import what you need, remove what you don't

6. **Create `home/your-hostname/home.nix`:**
   ```nix
   { config, pkgs-unstable, ... }:
   (import ../default/home.nix { inherit config pkgs-unstable; }) // {
     home.packages = (import ../default/home.nix { inherit config pkgs-unstable; }).home.packages ++ [
       pkgs-unstable.discord  # Add your desktop-specific packages
       pkgs-unstable.vscode
     ];
   }
   ```

7. **Apply:**
   ```bash
   sudo nixos-rebuild switch --flake .#your-hostname
   ```

### Intermediate Path

1. **Understand the inheritance chain:**
   - `hosts/default/configuration.nix` = shared boot, graphics, networking
   - `hosts/your-hostname/configuration.nix` = imports default + adds your GPU driver, hostname, optional modules
   - NixOS merges both during evaluation

2. **Customize by layering:**
   ```nix
   # In hosts/your-hostname/configuration.nix
   imports = [
     ../default/configuration.nix        # Get all common stuff
     ./hardware-configuration.nix        # Your hardware
     ../../modules/gaming.nix            # Add gaming if needed
   ];
   
   # Only add what's different for this host
   networking.hostName = "my-laptop";
   boot.loader.efi.canTouchEfiVariables = true;
   ```

3. **Create matching home config:**
   ```nix
   # In home/your-hostname/home.nix
   { config, pkgs-unstable, ... }:
   let
     common = import ../default/home.nix { inherit config pkgs-unstable; };
   in
   common // {
     home.packages = common.home.packages ++ [
       pkgs-unstable.discord
       pkgs-unstable.vscode
     ];
   }
   ```

4. **Test before applying:**
   ```bash
   nix flake check .#your-hostname              # Validate syntax
   nixos-rebuild build --flake .#your-hostname  # Build without applying
   nixos-rebuild switch --flake .#your-hostname # Apply when ready
   ```

### Advanced Path

1. **Create a new host configuration:**
   ```bash
   mkdir -p hosts/workstation/{,home}
   cp hosts/nixos/configuration.nix hosts/workstation/
   cp hosts/nixos/hardware-configuration.nix hosts/workstation/
   ```

2. **Reference in `flake.nix`:**
   ```nix
   workstation = nixpkgs-unstable.lib.nixosSystem {
     inherit system;
     specialArgs = { inherit inputs pkgs-unstable; };
     modules = [
       ./hosts/workstation/configuration.nix
       home-manager.nixosModules.home-manager
       {
         home-manager.useUserPackages = true;
         home-manager.extraSpecialArgs = { inherit inputs pkgs-unstable; };
         home-manager.users.shyam = import ./home/workstation/home.nix;
       }
     ];
   };
   ```

3. **Write a new reusable module** (`modules/custom-feature.nix`):
   ```nix
   { config, pkgs, lib, ... }:
   {
     options.custom.myFeature.enable = lib.mkEnableOption "my custom feature";
     
     config = lib.mkIf config.custom.myFeature.enable {
       services.myService.enable = true;
       environment.systemPackages = [ pkgs.myTool ];
       
       # Custom options
       custom.myFeature.setting = lib.mkOption {
         type = lib.types.str;
         default = "value";
         description = "My setting";
       };
     };
   }
   ```

4. **Deploy to remote:**
   ```bash
   # Build locally, copy to remote
   nixos-rebuild switch --flake .#workstation --target-host user@hostname
   
   # Or build on remote (slower, no copy)
   nixos-rebuild switch --flake .#workstation --target-host user@hostname --build-host user@hostname
   ```

5. **Check module composition:**
   ```bash
   nix eval --json .#nixosConfigurations.workstation.config.services | jq .
   ```

---

## Key Concepts

### No Duplication
**Old approach:** Copy `imports = [ ../../modules/base.nix ../../modules/nix-settings.nix ... ]` into every host config (repetition, maintenance nightmare).

**New approach:** `hosts/default/configuration.nix` declares the common imports once. Other hosts do `imports = [ ../default/configuration.nix ];` and add only their differences.

### Modular Composition
Modules are optional and reusable:
- Want gaming but not multimedia? Import only `gaming.nix`.
- Desktop needs `audio.nix` (no 32-bit); laptop needs `audio-laptop.nix` (with 32-bit).
- Surface devices share common settings in `surface-common.nix`, then diverge with `nvidia-surface.nix` vs `intel-surface.nix`.

### Inheritance Via Import
This is **not OOP inheritance**. It's standard NixOS module composition:
1. Import a file (load its attributes)
2. Merge attributes with `//` operator or attribute extension
3. Later definitions override earlier ones

Example:
```nix
imports = [ ../default/configuration.nix ];
services.openssh.enable = true;  # Override/add
```

### Home-Manager Integration
Each host gets its own home-manager configuration:
- `home/default/home.nix` — common packages (git, neovim, direnv)
- `home/your-hostname/home.nix` — extends default + adds host-specific packages (discord, vscode for desktop; moonlight-qt for laptop)

---

## Troubleshooting

| Issue | Solution |
|---|---|
| `error: attribute ... is missing` | A module expects an input (e.g., `pkgs-unstable`) that isn't passed. Check `flake.nix` specialArgs. |
| `option ... is not defined` | Enable the module that defines it, or add a custom option definition in a new module. |
| `path does not exist` | Check import paths use `../` not `/`. Relative paths are evaluated in the file's directory. |
| Build takes 24+ hours | Building on low-power device (e.g., passive Surface Book). Use `--build-host` to build on faster machine first. |
| `nix-copy-closure` fails with signature errors | Remote has strict signature checking. Simplify trusted-public-keys and set `require-sigs = false` for passive clients. |
| Module not being applied | Check both the `imports` list and flake.nix modules array. Import order matters only for option defaults. |

---

## File Editing Tips

- **Keep `hosts/default/configuration.nix` lean:** Only include settings needed by *all* three systems.
- **Host-specific settings belong in `hosts/{hostname}/configuration.nix`:** GPU drivers, boot options, hostname, firewall rules.
- **Common packages in `home/default/home.nix`:** git, neovim, direnv — things every user needs.
- **Desktop packages in `home/nixos/home.nix`:** discord, vscode, thunderbird — things only desktop needs.
- **Test locally first:** Use `nixos-rebuild build` before `switch` to catch errors early.

---

## Example: Adding a New Package

### Beginner
Edit `home/default/home.nix`:
```nix
home.packages = [
  pkgs.nextcloud-client
  pkgs.obsidian
  pkgs.git
  pkgs.my-new-package  # Add here
];
```

### Intermediate
Create `modules/my-package.nix`:
```nix
{ config, pkgs, lib, ... }:
{
  options.custom.myPackage.enable = lib.mkEnableOption "my package";
  
  config = lib.mkIf config.custom.myPackage.enable {
    environment.systemPackages = [ pkgs.my-new-package ];
  };
}
```

Then in host config:
```nix
imports = [ ../../modules/my-package.nix ];
custom.myPackage.enable = true;
```

### Advanced
Create a parametrized module with options:
```nix
{ config, pkgs, lib, ... }:
{
  options = {
    custom.myPackage = {
      enable = lib.mkEnableOption "my package";
      version = lib.mkOption {
        type = lib.types.str;
        default = "latest";
      };
    };
  };
  
  config = lib.mkIf config.custom.myPackage.enable {
    environment.systemPackages = [
      pkgs.callPackage ../../pkgs/my-package.nix { version = config.custom.myPackage.version; }
    ];
  };
}
```

---

## Resources

- [NixOS Manual](https://nixos.org/manual/nixos/unstable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nix Flakes Documentation](https://nixos.wiki/wiki/Flakes)
- [NixOS Hardware Support](https://github.com/NixOS/nixos-hardware)
- [Nix Language Reference](https://nix.dev/manual/nix/2.18/language/index)
