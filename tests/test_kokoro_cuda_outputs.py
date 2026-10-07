"""Exercise Kokoro's actual CUDA preFixup and output-propagation hook.

Run from the repository root: python3 tests/test_kokoro_cuda_outputs.py
This evaluates derivations but does not build CUDA or activate Home Manager.
"""

import json
from pathlib import Path
import subprocess
import tempfile
import unittest


class KokoroCudaOutputsTest(unittest.TestCase):
    def test_runtime_output_propagation(self):
        drv = subprocess.check_output(
            [
                "nix", "eval", "--raw", "--impure", "--no-write-lock-file",
                "--expr",
                'let f = builtins.getFlake (toString ./.); in '
                '(builtins.head (builtins.filter (p: p.name == "kokoro-say") '
                'f.homeConfigurations."iperez@epsilon".config.home.packages)).drvPath',
            ],
            text=True,
        ).strip()
        result = json.loads(subprocess.check_output(
            ["nix", "derivation", "show", "--recursive", drv], text=True,
        ))
        derivations = result.get("derivations", result)
        expected = {"cuda_nvrtc", "libcublas", "libcufft", "libcurand", "libnvjitlink", "cudnn"}
        checked = set()
        for derivation in derivations.values():
            attrs = derivation.get("structuredAttrs")
            if attrs is None:
                attrs = json.loads(derivation.get("env", {}).get("__json", "{}"))
            name = attrs.get("pname")
            if name not in expected or "lib" not in attrs.get("outputs", []):
                continue
            hooks = [
                path for path in attrs.get("nativeBuildInputs", [])
                if isinstance(path, str) and path.endswith("-buildRedistHook.bash")
            ]
            self.assertEqual(len(hooks), 1, f"Missing or ambiguous CUDA hook for {name}")
            with self.subTest(package=name), tempfile.TemporaryDirectory() as directory:
                outputs = attrs["propagatedBuildOutputs"]
                self.assertIsInstance(outputs, list)
                fixture = Path(directory)
                # Bash receives the output names as positional arguments, not code.
                script = '''set -eu
nixLog() { :; }
printWords() { printf '%s\\n' "$*"; }
source "$1"
root="$2"
shift 2
propagatedBuildOutputs=("$@")
for output in out "$@"; do
    printf -v "$output" '%s/%s' "$root" "$output"
done
''' + attrs.get("preFixup", "") + '\nfixupCudaPropagatedBuildOutputsToOut\n'
                completed = subprocess.run(
                    ["bash", "-c", script, "cuda-regression", hooks[0], directory, *outputs],
                    capture_output=True, text=True,
                )
                self.assertEqual(completed.returncode, 0, completed.stderr)
                self.assertEqual(completed.stdout, "")
                self.assertEqual(completed.stderr, "")
                propagated = fixture / "out/nix-support/propagated-build-inputs"
                self.assertEqual(
                    propagated.read_text(),
                    "".join(f"{fixture / output}\n" for output in outputs),
                )
                checked.add(name)
        self.assertTrue(
            expected <= checked,
            f"Missing CUDA runtime coverage: {checked}",
        )


if __name__ == "__main__":
    unittest.main()
