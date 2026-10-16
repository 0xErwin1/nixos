{
  lib,
  buildNpmPackage,
  nodejs,
  makeWrapper,
}:

# The desktop app does not embed its MCP server: it looks up
# `openpencil-mcp-http` on PATH and spawns it. Agents then reach that server
# through the stdio `openpencil-mcp` client. The lockfile beside this file pins
# the published package and its dependency tree; regenerate it with
# `npm install --package-lock-only --ignore-scripts` when bumping the version.
buildNpmPackage {
  pname = "open-pencil-mcp";
  version = "0.15.1";

  src = ./.;

  npmDepsHash = "sha256-L9TO4SSgYO2/FEhWN5Za+k1K7hPPf2q4opxiOHhsf/U=";

  dontNpmBuild = true;
  # Only core-js declares an install script, and it prints a banner.
  npmFlags = [ "--ignore-scripts" ];

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib $out/bin
    cp -r node_modules $out/lib/
    for bin in openpencil-mcp openpencil-mcp-http; do
      makeWrapper ${lib.getExe nodejs} $out/bin/$bin \
        --add-flags $out/lib/node_modules/@open-pencil/mcp/$(
          ${lib.getExe nodejs} -p "require('./node_modules/@open-pencil/mcp/package.json').bin['$bin']"
        )
    done
    runHook postInstall
  '';

  meta = {
    description = "MCP server for the OpenPencil design editor";
    homepage = "https://openpencil.dev/programmable/mcp-server";
    license = lib.licenses.mit;
    mainProgram = "openpencil-mcp";
  };
}
