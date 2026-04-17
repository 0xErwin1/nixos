{ pkgs }:

pkgs.buildGoModule rec {
  pname = "engram";
  version = "1.12.0";

  src = pkgs.fetchFromGitHub {
    owner = "Gentleman-Programming";
    repo = "engram";
    rev = "v${version}";
    hash = "sha256-qPANLsBeF4hDjJShnBc2Pn7Mg2eh1IlvDAEfUc8YE8s=";
  };

  vendorHash = "sha256-wnRtuBn5H+UdWkXucpfHPEbFosVCUa8i9hVRXg5Wqc4=";
  proxyVendor = true;

  subPackages = [ "cmd/engram" ];

  env.CGO_ENABLED = "0";

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  meta = with pkgs.lib; {
    description = "Persistent memory for AI coding agents";
    homepage = "https://github.com/Gentleman-Programming/engram";
    license = licenses.mit;
    mainProgram = "engram";
    platforms = platforms.linux ++ platforms.darwin;
  };
}
