{ pkgs }:

pkgs.buildGoModule rec {
  pname = "engram";
  version = "1.15.13";

  src = pkgs.fetchFromGitHub {
    owner = "Gentleman-Programming";
    repo = "engram";
    rev = "v${version}";
    hash = "sha256-EJilI+OKeBJ0elbsOi9ch+q+cICi3DYJ1FijvxXF3DA=";
  };

  vendorHash = "sha256-JBwLW62M6SFXqgYKeSdUI136B42f3h43V9ud1qUW484=";
  proxyVendor = true;

  doCheck = false;

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
