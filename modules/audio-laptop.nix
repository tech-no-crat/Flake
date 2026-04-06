# modules/audio-laptop.nix
# Audio system configuration for laptops (PipeWire with 32-bit support)
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
