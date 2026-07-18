{ pkgs, ... }:
let
  model = pkgs.fetchurl {
    url = "https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/kokoro-v1.0.onnx";
    hash = "sha256-fV347PfUsYeAFaMmhgU/0O6+K8N3I0YIdkzA7zY2psU=";
  };

  voices = pkgs.fetchurl {
    url = "https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/voices-v1.0.bin";
    hash = "sha256-vKYQuDCOjZnzLm/kGX5+wBZ5Jk7+0MrJFA/pwp8fv30=";
  };

  runtimeLibraryPath = pkgs.lib.makeLibraryPath (
    (with pkgs.cudaPackages_13; [
      cuda_cudart
      cuda_nvrtc
      libcublas
      libcufft
      libcurand
      cudnn
    ])
    ++ [
      pkgs.zlib
      pkgs.stdenv.cc.cc.lib
      pkgs.libffi
      pkgs.libsndfile
    ]
  );

  kokoroSay = pkgs.writeShellApplication {
    name = "kokoro-say";
    runtimeInputs = [
      pkgs.espeak-ng
      pkgs.pipewire
      pkgs.python312
      pkgs.uv
    ];
    text = ''
      export LD_LIBRARY_PATH="/run/opengl-driver/lib:${runtimeLibraryPath}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      export UV_CACHE_DIR="''${XDG_CACHE_HOME:-$HOME/.cache}/kokoro/uv"

      uv run \
        --no-project \
        --python ${pkgs.python312}/bin/python \
        --with 'kokoro-onnx[gpu]==0.5.0' \
        --with 'soundfile==0.13.1' \
        python - "$@" <<'PYTHON'
      import argparse
      import subprocess
      import tempfile
      from pathlib import Path

      import onnxruntime as ort
      import soundfile as sf
      from kokoro_onnx import Kokoro


      def parse_args():
          parser = argparse.ArgumentParser(
              prog="kokoro-say",
              description="Generate Spanish speech locally with Kokoro.",
              epilog=(
                  "Prebuilt Python GPU packages are downloaded on first use and cached "
                  "under $XDG_CACHE_HOME/kokoro (or ~/.cache/kokoro)."
              ),
          )
          parser.add_argument(
              "--voice",
              default="ef_dora",
              help="Spanish Kokoro voice (default: ef_dora)",
          )
          parser.add_argument(
              "--speed",
              type=float,
              default=1.0,
              help="speech speed multiplier (default: 1.0)",
          )
          parser.add_argument(
              "--output",
              type=Path,
              help="retain the generated WAV at PATH instead of playing it",
          )
          parser.add_argument("text", nargs="+", help="Spanish text to speak")

          args = parser.parse_args()
          if args.speed <= 0:
              parser.error("--speed must be greater than zero")

          return parser, args


      def generate(text, voice, speed, output_path):
          providers = ort.get_available_providers()
          if "CUDAExecutionProvider" not in providers:
              raise RuntimeError(
                  f"CUDAExecutionProvider is unavailable; providers: {providers}"
              )

          session = ort.InferenceSession(
              "${model}",
              providers=["CUDAExecutionProvider"],
          )
          if "CUDAExecutionProvider" not in session.get_providers():
              raise RuntimeError(
                  f"CUDA initialization failed; active providers: {session.get_providers()}"
              )

          kokoro = Kokoro.from_session(session, "${voices}")
          samples, sample_rate = kokoro.create(
              text,
              voice=voice,
              speed=speed,
              lang="es",
          )

          sf.write(output_path, samples, sample_rate)


      def main():
          parser, args = parse_args()
          text = " ".join(args.text).strip()
          if not text:
              parser.error("text must not be empty")

          try:
              if args.output is not None:
                  output_path = args.output.expanduser()
                  generate(text, args.voice, args.speed, output_path)
                  print(f"Wrote {output_path}")
                  return

              with tempfile.TemporaryDirectory(prefix="kokoro-say-") as directory:
                  output_path = Path(directory) / "speech.wav"
                  generate(text, args.voice, args.speed, output_path)
                  subprocess.run(["pw-play", str(output_path)], check=True)
          except subprocess.CalledProcessError as error:
              parser.exit(error.returncode, "kokoro-say: playback failed\n")
          except Exception as error:
              parser.exit(1, f"kokoro-say: generation failed: {error}\n")


      if __name__ == "__main__":
          main()
      PYTHON
    '';
  };
in
{
  home.packages = [ kokoroSay ];
}
