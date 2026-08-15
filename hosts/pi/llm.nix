{ ... }:
# Local LLM serving on the Pi.
#
# Two engines side by side:
#  - ollama runs on the CPU cores; mainline-friendly and model-rich.
#  - rkllama drives the RK3588 NPU through the vendor rknpu driver and only
#    accepts .rkllm-converted models. It ships as a container and needs
#    privileged access to reach the NPU device nodes (/dev/dri, /dev/dma_heap).
#
# Both APIs listen on the LAN: ollama on 11434, rkllama on 8080 (also
# Ollama-compatible under /api and OpenAI-compatible under /v1).
{
  services.ollama = {
    enable = true;
    host = "0.0.0.0";
  };

  virtualisation.oci-containers = {
    backend = "podman";
    containers.rkllama = {
      image = "ghcr.io/notpunchnox/rkllama:main";
      ports = [ "8080:8080" ];
      volumes = [ "/var/lib/rkllama/models:/opt/rkllama/models" ];
      extraOptions = [ "--privileged" ];
    };
  };

  systemd.tmpfiles.rules = [ "d /var/lib/rkllama/models 0755 root root -" ];

  networking.firewall.allowedTCPPorts = [
    11434
    8080
  ];
}
