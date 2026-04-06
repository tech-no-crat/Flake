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

  # Desktop X Server setup (with AMD GPU)
  services.xserver.videoDrivers = [ "amdgpu" ];

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
