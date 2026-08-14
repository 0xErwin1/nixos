{ pkgs }:

pkgs.buildGoModule rec {
  pname = "gentle-ai";
  version = "2.4.0-rc.8";

  src = pkgs.fetchFromGitHub {
    owner = "Gentleman-Programming";
    repo = "gentle-ai";
    rev = "v${version}";
    hash = "sha256-plB9mxudrfZJBPpHjPRyTFi318TyggiEVQrOxdjwYAc=";
  };

  vendorHash = "sha256-qeeD+omJzlqolHGzGx2E60fEucjweb62UQY3N/0xxgs=";
  proxyVendor = true;

  doCheck = false;

  subPackages = [ "cmd/gentle-ai" ];

  env.CGO_ENABLED = "0";

  # releaseMinisignPublicKeys is deliberately left unset: the self-upgrade path must
  # never replace a Nix-store binary, and an empty key set makes it fail closed.
  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  meta = with pkgs.lib; {
    description = "Multi-client AI coding harness toolkit";
    homepage = "https://github.com/Gentleman-Programming/gentle-ai";
    license = licenses.asl20;
    mainProgram = "gentle-ai";
    platforms = platforms.linux ++ platforms.darwin;
  };
}
