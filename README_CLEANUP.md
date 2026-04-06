# NixOS Cleanup Summary - Quick Reference

## What's Wrong With Your Configuration?

**TL;DR:** You've accidentally created a mixed pattern where `hosts/default/` acts like a common base but is loaded alongside `hosts/nixos/configuration.nix`, causing massive duplication. Surface devices don't use this pattern at all, causing inconsistency.

---

## THE BIG PROBLEMS

### 1. 🔴 Three Different Patterns Being Used

#### Pattern 1: nixos config
- Imports `hosts/default/configuration.nix` alongside `hosts/nixos/configuration.nix` (WRONG)
- Gets all settings TWICE due to NixOS's module merging
- Then also directly has the same settings in `hosts/nixos/configuration.nix`

#### Pattern 2: Surface configs
- Standalone, no imports from common
- Each has identical settings copy-pasted
- Missing base settings that `nixos` has

#### Pattern 3: Home configs
- `home/default/home.nix` is orphaned (not imported in flake)
- Surface configs duplicate packages from each other

### 2. 🟠 Duplication By The Numbers
- **~400 lines of duplicated configuration**
- Same settings appearing in 2-4 different files
- Copy-paste prevents consistency (e.g., surface-passive missing SSH keys)

### 3. 🟡 Missing Features
- `surface-book-passive` can't SSH because SSH keys are missing
- Inconsistent nix.settings across hosts
- Dead code (30-line commented-out nvidia block)

---

## The Three Documents I Created For You

1. **`CLEANUP_ANALYSIS.md`** (Read This First)
   - Overview of all duplicates
   - Table showing what's duplicated where
   - Explains the architectural problem

2. **`IMPLEMENTATION_FEEDBACK.md`** (For Understanding)
   - Technical explanation of what went wrong
   - Why each pattern is incorrect
   - Architecture diagrams
   - Line-by-line issue analysis

3. **`MARKED_FOR_CLEANUP.md`** (For Taking Action)
   - Exact file locations with line numbers
   - Code blocks to DELETE
   - Code blocks to ADD
   - Checklist for completion

4. **`PROPOSED_STRUCTURE.md`** (Template for New Code)
   - Complete template code for all new modules
   - Updated host configuration examples
   - Updated home configuration examples
   - Updated flake.nix snippet

---

## Quick Fix Timeline

### Phase 1: Preparation (30 minutes)
1. Read `CLEANUP_ANALYSIS.md`
2. Review `MARKED_FOR_CLEANUP.md` to understand scope
3. Review `PROPOSED_STRUCTURE.md` for the solutions

### Phase 2: Create New Modules (1 hour)
Create 8 new files in `modules/`:
- `base.nix`
- `gnome.nix`
- `audio.nix`
- `audio-laptop.nix`
- `nix-settings.nix`
- `surface-common.nix`
- `nvidia-surface.nix`
- `intel-surface.nix`

### Phase 3: Update Host Configs (1 hour)
Refactor 3 files in `hosts/`:
- `nixos/configuration.nix`
- `surface-book-active/configuration.nix`
- `surface-book-passive/configuration.nix`

### Phase 4: Update Home Configs (30 minutes)
Refactor 2 files in `home/`:
- `default/home.nix`
- `surface-book-active/home.nix`
- `surface-book-passive/home.nix`

### Phase 5: Cleanup (15 minutes)
- Update `flake.nix`
- Delete `hosts/default/configuration.nix`
- Fix `modules/multimedia.nix` comment
- Test rebuild

**Total Time: ~3 hours**

---

## Files To Delete/Change

### DELETE
- `hosts/default/configuration.nix` (entire file - after extracting to modules)

### MODIFY
- `flake.nix` - Remove import of `./hosts/default/configuration.nix`
- `hosts/nixos/configuration.nix` - Replace content with module imports
- `hosts/surface-book-active/configuration.nix` - Replace content with module imports
- `hosts/surface-book-passive/configuration.nix` - Replace content with module imports + ADD SSH keys
- `home/default/home.nix` - Confirm as base
- `home/surface-book-active/home.nix` - Make inherit from default
- `home/surface-book-passive/home.nix` - Make inherit from default
- `modules/multimedia.nix` - Fix header comment

### CREATE
- `modules/base.nix`
- `modules/gnome.nix`
- `modules/audio.nix`
- `modules/audio-laptop.nix`
- `modules/nix-settings.nix`
- `modules/surface-common.nix`
- `modules/nvidia-surface.nix`
- `modules/intel-surface.nix`

---

## Critical Issues To Fix First

### 🔴 CRITICAL #1: surface-book-passive Missing SSH Keys
**File:** `hosts/surface-book-passive/configuration.nix`
**Problem:** User can't SSH into device
**Solution:** Add this line to user setup:
```nix
openssh.authorizedKeys.keys = [
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINmAV4/B3jWOIJPgexSzCDDcK1lb+fD2tzA0i+Lxxgs3 shyam@clerics.ca"
];
```

### 🔴 CRITICAL #2: Flake Imports Wrong Config
**File:** `flake.nix` line 44-45
**Problem:** `nixos` config imports both `hosts/nixos` AND `hosts/default`, causing duplication
**Solution:** Delete `./hosts/default/configuration.nix` from modules list

### 🟠 MEDIUM #3: 30 Line Dead Code Block
**File:** `hosts/surface-book-passive/configuration.nix` lines 54-83
**Problem:** Entire commented-out nvidia block (device doesn't have nvidia)
**Solution:** Delete entire block

---

## Key Architectural Changes

### What's Currently Happening (WRONG ❌)
```
flake.nix:
  nixos config = [
    ./hosts/nixos/configuration.nix          (has all settings)
    + ./hosts/default/configuration.nix      (SAME settings again!)
    → Results in setting 2x duplication
  ]

  surface-book-active = [
    ./hosts/surface-book-active/config.nix   (independent, duplicates nixos)
  ]

  surface-book-passive = [
    ./hosts/surface-book-passive/config.nix  (independent, missing SSH keys!)
  ]
```

### What Should Happen (RIGHT ✓)
```
flake.nix:
  nixos = [
    ./hosts/nixos/configuration.nix         (imports modules)
    → No duplication, all hosts identical settings come from modules
  ]

  surface-book-active = [
    ./hosts/surface-book-active/config.nix  (imports same base modules)
    + ./modules/nvidia-surface.nix
  ]

  surface-book-passive = [
    ./hosts/surface-book-passive/config.nix (imports same base modules)
    + ./modules/intel-surface.nix
  ]
```

---

## Testing After Implementation

```bash
# Build without switching (safe to test)
nix flake check                          # Check flake syntax
nixos-rebuild build --flake .#nixos      # Build nixos config
nixos-rebuild build --flake .#surface-book-active   # Build active
nixos-rebuild build --flake .#surface-book-passive  # Build passive

# After confirming builds work:
sudo nixos-rebuild switch --flake .#nixos

# On surface devices:
sudo nixos-rebuild switch --flake .#surface-book-active
sudo nixos-rebuild switch --flake .#surface-book-passive

# Verify SSH works on surface-passive
ssh shyam@surface-book-passive
```

---

## Document Guide

| Document | Purpose | When to Read |
|---|---|---|
| **This file** | Quick overview and timeline | Start here (you're reading it!) |
| `CLEANUP_ANALYSIS.md` | Full problem analysis | After this, understand the scope |
| `IMPLEMENTATION_FEEDBACK.md` | Deep technical explanation | Understand WHY things are wrong |
| `MARKED_FOR_CLEANUP.md` | Exact code locations | When removing/adding code |
| `PROPOSED_STRUCTURE.md` | New code templates | When creating new files |

---

## Success Criteria

✓ After cleanup is complete:
- [ ] No duplication of common settings across configs
- [ ] `hosts/default/configuration.nix` deleted
- [ ] `surface-book-passive` can SSH in
- [ ] All three configs build without error
- [ ] Configuration reduced from ~400 lines duplication to ~75% less
- [ ] Modules are reusable and consistent
- [ ] Home manager setup properly inherited

---

## Questions?

The documents provide:
- **Specific line numbers** for every issue
- **Code blocks** showing exactly what to delete/add
- **Template code** ready to use
- **Architecture diagrams** explaining the pattern
- **Checklist** to track progress

Use `MARKED_FOR_CLEANUP.md` as your action guide with `PROPOSED_STRUCTURE.md` as the template sourcecode.

Good luck! 🚀

