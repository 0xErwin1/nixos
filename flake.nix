{
  description = "Your new nix config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    pi-harness = {
      url = "github:0xErwin1/pi-harness";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:0xErwin1/nixvim";
    };

    rofiAyuDarkTheme = {
      url = "github:regolith-linux/regolith-styles";
      flake = false;
    };

    firefoxAddons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zenBrowserFlake = {
      url = "github:0xc000022070/zen-browser-flake";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dbflux = {
      url = "github:0xErwin1/dbflux/nightly";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak";

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nix-flatpak,
      deploy-rs,
      ...
    }@inputs:
    let
      inherit (self) outputs;

      overlays = {
        default =
          final: prev:
          (inputs.dbflux.overlays.default final prev)
          // {
            dbflux-nightly = inputs.dbflux.packages.${final.stdenv.hostPlatform.system}.dbflux-nightly;
            brave-origin-nightly = final.callPackage "${self}/pkgs/brave-origin-nightly" { };
            claude-code-latest = final.callPackage "${self}/pkgs/claude-code-latest" { };
            claude-desktop = final.callPackage "${self}/pkgs/claude-desktop" { };
            ccstatusline = final.callPackage "${self}/pkgs/ccstatusline" { };
            helium = final.callPackage "${self}/pkgs/helium" { };
            engram = final.callPackage "${self}/pkgs/engram" { };
            opencode = final.callPackage "${self}/pkgs/opencode" { };
            tuicr = final.callPackage "${self}/pkgs/tuicr" { };
            codegraph = final.callPackage "${self}/pkgs/codegraph" { };
            maestro-studio = final.callPackage "${self}/pkgs/maestro-studio" { };
          };
      };

      pkgsEpsilon = import nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
        overlays = [ overlays.default ];
      };

      pkgszeta = import nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
        overlays = [ overlays.default ];
      };

      pkgsPi = import nixpkgs {
        system = "aarch64-linux";
        config.allowUnfree = true;
        overlays = [ overlays.default ];
      };

      # Read wireguard local config at flake evaluation time (requires --impure).
      # Returns {} if the file does not exist, so builds work on machines without it.
      wireguardLocalPath = "/home/iperez/.ssh/wireguard/default.nix";
      wireguardLocal = if builtins.pathExists wireguardLocalPath then import wireguardLocalPath else { };
    in
    {
      inherit overlays pkgsPi;

      deploy = {
        nodes = {
          pi-host-bootstrap = {
            hostname = "10.42.0.2";
            sshUser = "iperez";
            interactiveSudo = true;
            remoteBuild = true;
            autoRollback = true;
            magicRollback = true;
            profilesOrder = [ "system" "home" ];
            profiles = {
              system = {
                user = "root";
                path = deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.pi;
              };
              home = {
                user = "iperez";
                path = deploy-rs.lib.aarch64-linux.activate.home-manager self.homeConfigurations."iperez@pi";
              };
            };
          };

          pi-host = {
            hostname = "10.0.0.2";
            sshUser = "iperez";
            interactiveSudo = true;
            remoteBuild = true;
            autoRollback = true;
            magicRollback = true;
            profilesOrder = [ "system" "home" ];
            profiles = {
              system = {
                user = "root";
                path = deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.pi;
              };
              home = {
                user = "iperez";
                path = deploy-rs.lib.aarch64-linux.activate.home-manager self.homeConfigurations."iperez@pi";
              };
            };
          };
        };
      };

      nixosConfigurations = {
        epsilon = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs wireguardLocal; };
          modules = [
            ./hosts/epsilon
            nix-flatpak.nixosModules.nix-flatpak
          ];
        };

        zeta = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs wireguardLocal; };
          modules = [ ./hosts/zeta ];
        };

        pi = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs wireguardLocal; };
          modules = [ ./hosts/pi ];
        };
      };

      homeConfigurations = {
        "iperez@delta" = home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsEpsilon;
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [ ./home-manager/delta ];
        };

        "iperez@epsilon" = home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsEpsilon;
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [ ./home-manager/epsilon ];
        };

        "iperez@zeta" = home-manager.lib.homeManagerConfiguration {
          pkgs = pkgszeta;
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [ ./home-manager/zeta ];
        };

        "iperez@pi" = home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsPi;
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [ ./home-manager/pi ];
        };
      };

      checks.x86_64-linux =
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;

          # The functional tests read the evaluated flake (home configs, inputs,
          # checks) plus the source tree for file-content assertions. Passing them
          # in avoids a self-referential `getFlake`, which pure eval rejects on a
          # store path.
          flakeView = {
            inherit (self) homeConfigurations checks;
            inherit inputs;
          };

          # Force the test's `assert` guards during evaluation, then materialize a
          # trivial output. If any assertion fails, `nix flake check` fails here.
          functionalCheck =
            name: testFile: testArgs:
            let
              evaluated = import testFile testArgs;
            in
            pkgs.runCommandLocal name { assertionOutcome = builtins.seq evaluated "passed"; } ''
              printf 'ai harness functional test %s: %s\n' ${nixpkgs.lib.escapeShellArg name} "$assertionOutcome" > "$out"
            '';
        in
        {
          ai-harness-readiness =
            pkgs.runCommandLocal "ai-harness-readiness"
              {
                nativeBuildInputs = [
                  pkgs.gnugrep
                  pkgs.python3
                ];
              }
              ''
                set -eu

                grep -F /home/iperez/.config/ai-harness/secrets/mcp.env ${./ai/support/secrets-env-contract.md} >/dev/null
                grep -F /home/iperez/.config/ai-harness/secrets/api.env ${./ai/support/secrets-env-contract.md} >/dev/null
                grep -F AI_HARNESS_MCP_ENV_FILE ${./ai/support/secrets-env-contract.md} >/dev/null
                grep -F AI_HARNESS_API_ENV_FILE ${./ai/support/secrets-env-contract.md} >/dev/null
                grep -F "AI harness required env file is missing" ${./home-manager/global/ai-harness.nix} >/dev/null

                if find ${./ai} -type l -print -quit | grep -q .; then
                  echo "Managed AI asset tree must not contain symlinks." >&2
                  find ${./ai} -type l -print >&2
                  exit 1
                fi

                if grep -R -F "/.tabularium/AI" ${./ai} ${./home-manager/global/ai-harness.nix} ${./home-manager/global/ai.nix} ${./tests/ai-harness-projections.nix}; then
                  echo "Managed AI harness files must not reference Tabularium as the canonical source." >&2
                  exit 1
                fi

                token_pattern='(Bearer[[:space:]]+[A-Za-z0-9._~+/=-]{20,}|sk-[A-Za-z0-9]{20,}|gh[pousr]_[A-Za-z0-9_]{20,}|xox[baprs]-[A-Za-z0-9-]{20,}|(api[_-]?key|token|secret|password)[[:space:]]*[:=][[:space:]]*"?[A-Za-z0-9_./+-]{16,})'
                if grep -R -E -i "$token_pattern" ${./ai} ${./home-manager/global/ai-harness.nix} ${./home-manager/global/ai.nix} ${./tests/ai-harness-projections.nix}; then
                  echo "Token-like literal value detected in managed AI harness files." >&2
                  exit 1
                fi

                python3 - \
                  ${./ai/shared/engram-protocol.md} \
                  ${./ai/claude/engram-protocol.md} \
                  ${./ai/codex/engram-instructions.md} \
                  ${./ai/codex/engram-compact-prompt.md} <<'PY'
                import re
                import sys
                from pathlib import Path

                protocol, claude, codex, compact = map(Path, sys.argv[1:])
                text = protocol.read_text()
                sections = dict(
                    re.findall(
                        r'<!-- section:([a-z-]+) -->\n(.*?)\n<!-- /section:\1 -->',
                        text,
                        re.S,
                    )
                )
                required = {'full', 'slim', 'passive-capture', 'compact'}
                missing = required - sections.keys()
                if missing:
                    raise SystemExit(f'Engram protocol missing sections: {sorted(missing)}')

                expected = {
                    claude: sections['full'] + '\n',
                    codex: sections['full'] + '\n\n' + sections['passive-capture'] + '\n',
                    compact: sections['compact'] + '\n',
                }
                for path, content in expected.items():
                    actual = path.read_text()
                    if '<!-- section:' in actual or '<!-- /section:' in actual:
                        raise SystemExit(f'Rendered Engram projection contains section markers: {path}')
                    if actual != content:
                        raise SystemExit(f'Rendered Engram projection drifted: {path}')
                PY

                touch $out
              '';

          pi-harness-wiring = functionalCheck "pi-harness-wiring" ./tests/pi-harness-wiring.nix {
            flake = flakeView;
          };

          ai-harness-projections =
            functionalCheck "ai-harness-projections" ./tests/ai-harness-projections.nix
              {
                flake = flakeView;
                flakePath = self.outPath;
              };

          pi-outputs = functionalCheck "pi-outputs" ./tests/pi-outputs.nix {
            flake = self // {
              inherit pkgsPi;
            };
            flakePath = self.outPath;
          };
        }
        // deploy-rs.lib.x86_64-linux.deployChecks self.deploy;

      devShells.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.mkShell {
        DEVENV_TUI = "false";
        packages = with nixpkgs.legacyPackages.x86_64-linux; [
          nixpkgs.legacyPackages.x86_64-linux.deploy-rs
          devenv
          secretspec
          wireguard-tools
          openssh
          nix
          nixpkgs.legacyPackages.x86_64-linux.home-manager
          git
          nil
          nixfmt-rfc-style
        ];
      };
    };
}
