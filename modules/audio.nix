# modules/audio.nix
# Audio system configuration (PipeWire) - base version without 32-bit support
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
