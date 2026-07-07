{ pkgs }:

pkgs.buildNpmPackage rec {
  pname = "codegraph";
  version = "1.1.6";

  src = pkgs.fetchFromGitHub {
    owner = "colbymchenry";
    repo = "codegraph";
    rev = "v${version}";
    hash = "sha256-lg3hmgKV65llqOKMIEdf6gcjpKOvpI2zBJEkDmHq8Y0=";
  };

  npmDepsHash = "sha256-oIdZ7JrUKnBMj3Pora2TT/LkDJa+/ihVd8ZypTrG1Q0=";

  # node:sqlite (used by the graph store) needs >=22.5; the wrapper is pinned to this node.
  nodejs = pkgs.nodejs_22;

  meta = with pkgs.lib; {
    description = "Code intelligence and knowledge graph for any codebase (CLI + MCP)";
    homepage = "https://github.com/colbymchenry/codegraph";
    license = licenses.mit;
    mainProgram = "codegraph";
    platforms = platforms.linux;
  };
}
