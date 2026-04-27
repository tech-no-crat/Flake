# modules/audio.nix
# Audio system configuration (PipeWire) - base version without 32-bit support
{ pkgs, ... }:

{
  # Audio setup
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;

    # Virtual noise-canceling microphone via rnnoise.
    # Select "Noise Canceling source" as your mic in Discord / any app.
    extraConfig.pipewire."99-noise-cancellation" = {
      "context.modules" = [
        {
          name = "libpipewire-module-filter-chain";
          args = {
            "node.description" = "Noise Canceling source";
            "media.name"       = "Noise Canceling source";
            "filter.graph" = {
              nodes = [
                {
                  type    = "ladspa";
                  name    = "rnnoise";
                  plugin  = "${pkgs.rnnoise-plugin}/lib/ladspa/librnnoise_ladspa.so";
                  label   = "noise_suppressor_mono";
                  control = {
                    "VAD Threshold (%)"           = 50.0;
                    "VAD Grace Period (ms)"        = 200.0;
                    "Retroactive VAD Grace (ms)"   = 0.0;
                  };
                }
              ];
            };
            "capture.props" = {
              "node.name"    = "capture.rnnoise_source";
              "node.passive" = true;
              "audio.rate"   = 48000;
            };
            "playback.props" = {
              "node.name"   = "rnnoise_source";
              "media.class" = "Audio/Source";
              "audio.rate"  = 48000;
            };
          };
        }
      ];
    };
  };
}
