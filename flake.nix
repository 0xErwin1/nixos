{
  description = "Your new nix config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    sops-nix = {
      url = "git+https://github.com/Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    atlas.url = "github:0xErwin1/atlas/nightly";

    gentle-ai-nix = {
      url = "github:0xErwin1/gentle-ai-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    brasa = {
      url = "github:0xErwin1/brasa";
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

    astal = {
      url = "github:aylur/astal";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ags = {
      url = "github:aylur/ags";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.astal.follows = "astal";
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Armbian vendor kernel (rk-6.1 BSP) for the Orange Pi 5 Plus, needed for
    # the rknpu driver that the rkllm/rkllama NPU stack requires.
    nixos-rk3588 = {
      url = "github:gnull/nixos-rk3588";
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
            gentle-pi-runtime-repair = final.callPackage "${self}/pkgs/gentle-pi-runtime-repair" { };
            helium = final.callPackage "${self}/pkgs/helium" { };
            agent-integrations = final.callPackage "${self}/pkgs/agent-integrations";
            opencode = final.callPackage "${self}/pkgs/opencode" { };
            tuicr = final.callPackage "${self}/pkgs/tuicr" { };
            maestro-studio = final.callPackage "${self}/pkgs/maestro-studio" { };
            orca = final.callPackage "${self}/pkgs/orca/package.nix" { };
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

    in
    {
      inherit overlays pkgsPi;

      deploy = {
        nodes = {
          pi-host = {
            hostname = "192.168.1.100";
            sshUser = "iperez";
            remoteBuild = true;
            autoRollback = true;
            magicRollback = true;
            profilesOrder = [
              "system"
              "home"
            ];
            profiles = {
              system = {
                user = "root";
                interactiveSudo = true;
                path = deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.pi;
              };
              home = {
                user = "iperez";
                profilePath = "/home/iperez/.local/state/nix/profiles/home-manager";
                path = deploy-rs.lib.aarch64-linux.activate.home-manager self.homeConfigurations."iperez@pi";
              };
            };
          };
        };
      };

      nixosConfigurations = {
        epsilon = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./hosts/epsilon
            nix-flatpak.nixosModules.nix-flatpak
            inputs.sops-nix.nixosModules.sops
          ];
        };

        zeta = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./hosts/zeta
            inputs.sops-nix.nixosModules.sops
          ];
        };

        pi = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./hosts/pi
            inputs.sops-nix.nixosModules.sops
          ];
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
            if evaluated ? runtimeTest then
              pkgs.runCommandLocal name
                {
                  assertionOutcome = builtins.seq evaluated "passed";
                  nativeBuildInputs = [
                    pkgs.git
                    pkgs.gnugrep
                  ];
                }
                ''
                  set -eu

                  ${evaluated.runtimeTest}

                  printf 'ai harness functional test %s: %s\n' ${nixpkgs.lib.escapeShellArg name} "$assertionOutcome" > "$out"
                ''
            else
              pkgs.runCommandLocal name { assertionOutcome = builtins.seq evaluated "passed"; } ''
                printf 'ai harness functional test %s: %s\n' ${nixpkgs.lib.escapeShellArg name} "$assertionOutcome" > "$out"
              '';
        in
        {
          ai-harness-readiness =
            pkgs.runCommandLocal "ai-harness-readiness"
              (let
                homeFiles = builtins.attrValues self.homeConfigurations."iperez@epsilon".config.home.file;
                sourceForTarget = target:
                  (nixpkgs.lib.findFirst
                    (entry: entry.target == target)
                    (throw "Home Manager delivery is missing target: ${target}")
                    homeFiles
                  ).source;
              in
              {
                nativeBuildInputs = [
                  pkgs.gnugrep
                  pkgs.python3
                ];
                # These are the sources Home Manager actually delivers, rather
                # than an independently named renderer output.
                deliveryRoot = self.homeConfigurations."iperez@epsilon".config.home.file.gentle-ai.source;
                workClaudeDelivery = sourceForTarget ".claude-work/CLAUDE.md";
                workClaudeSkillsDelivery = sourceForTarget ".claude-work/skills";
                grokPolicyDelivery = sourceForTarget ".grok/AGENTS.md";
                grokSkillsDelivery = sourceForTarget ".grok/skills";
                renderedRoot = self.homeConfigurations."iperez@epsilon".config.programs.gentle-ai.rendered;
                agensActivation = self.homeConfigurations."iperez@epsilon".activationPackage;
              })
              ''
                set -eu

                grep -F /home/iperez/.config/ai-harness/secrets/mcp.env ${./ai/support/secrets-env-contract.md} >/dev/null
                grep -F /home/iperez/.config/ai-harness/secrets/api.env ${./ai/support/secrets-env-contract.md} >/dev/null
                grep -F AI_HARNESS_MCP_ENV_FILE ${./ai/support/secrets-env-contract.md} >/dev/null
                grep -F AI_HARNESS_API_ENV_FILE ${./ai/support/secrets-env-contract.md} >/dev/null
                grep -F "AI harness required env file is missing" ${./home-manager/global/ai-harness-gentle-ai.nix} >/dev/null

                if find ${./ai} -type l -print -quit | grep -q .; then
                  echo "Managed AI asset tree must not contain symlinks." >&2
                  find ${./ai} -type l -print >&2
                  exit 1
                fi

                if grep -R -F "/.tabularium/AI" ${./ai} ${./home-manager/global/ai-harness-gentle-ai.nix} ${./home-manager/global/ai.nix}; then
                  echo "Managed AI harness files must not reference Tabularium as the canonical source." >&2
                  exit 1
                fi

                token_pattern='(Bearer[[:space:]]+[A-Za-z0-9._~+/=-]{20,}|sk-[A-Za-z0-9]{20,}|gh[pousr]_[A-Za-z0-9_]{20,}|xox[baprs]-[A-Za-z0-9-]{20,}|(api[_-]?key|token|secret|password)[[:space:]]*[:=][[:space:]]*"?[A-Za-z0-9_./+-]{16,})'
                if grep -R -E -i "$token_pattern" ${./ai} ${./home-manager/global/ai-harness-gentle-ai.nix} ${./home-manager/global/ai.nix}; then
                  echo "Token-like literal value detected in managed AI harness files." >&2
                  exit 1
                fi

                python3 - \
                  ${./ai/skills} \
                  "$workClaudeSkillsDelivery" \
                  "$grokPolicyDelivery" \
                  "$grokSkillsDelivery" \
                  "$deliveryRoot" \
                  "$workClaudeDelivery" \
                  "$renderedRoot/tree" <<'PY'
                import json
                import sys
                from pathlib import Path

                (
                    canonical_skills,
                    work_claude_skills_delivery,
                    grok_policy_delivery,
                    grok_skills_delivery,
                    delivery_root,
                    work_claude_delivery,
                    rendered_root,
                ) = map(Path, sys.argv[1:])

                # Every locally authored skill now lives once, at ai/skills, and
                # must reach every client's own skills directory byte for byte --
                # this is what proves the single fill overlay in
                # home-manager/global/ai-harness-gentle-ai.nix actually lands the
                # same skill set everywhere instead of drifting back into four
                # copies.
                local_skill_names = sorted(
                    p.name for p in canonical_skills.iterdir() if p.is_dir() and p.name != "_shared"
                )
                if not local_skill_names:
                    raise SystemExit("no locally authored skills found under ai/skills")
                if "upstream-ai-sync" in local_skill_names:
                    raise SystemExit("upstream-ai-sync must be removed from ai/skills")

                # agens is excluded here: its `delivery = "copy"` materializes
                # skills imperatively at activation, not as a Nix store path this
                # build-time check can read; the activation-script assertion below
                # is what covers it.
                client_skills_dirs = {
                    "claude-code": rendered_root / ".claude/skills",
                    "opencode": rendered_root / ".config/opencode/skills",
                    "codex": rendered_root / ".codex/skills",
                    "pi": rendered_root / ".pi/agent/skills",
                    "grok": grok_skills_delivery,
                    "claude-work": work_claude_skills_delivery,
                }

                for client, skills_dir in client_skills_dirs.items():
                    if (skills_dir / "upstream-ai-sync").exists():
                        raise SystemExit(f"{client} still delivers the removed upstream-ai-sync skill")
                    for name in local_skill_names:
                        source_dir = canonical_skills / name
                        for source_file in sorted(f for f in source_dir.rglob("*") if f.is_file()):
                            rel = source_file.relative_to(source_dir)
                            target_file = skills_dir / name / rel
                            if not target_file.is_file():
                                raise SystemExit(f"{client} is missing local skill file {name}/{rel} at {target_file}")
                            if target_file.read_bytes() != source_file.read_bytes():
                                raise SystemExit(f"{client}'s {name}/{rel} does not match the canonical ai/skills copy")

                if (delivery_root / ".agents/skills").exists():
                    raise SystemExit(".agents/skills is retired and must no longer be delivered")
                if not (Path(__import__("os").environ["agensActivation"]) / "activate").is_file():
                    raise SystemExit("Agens copy activation was not generated")

                policies = {
                    "OpenCode": delivery_root / ".config/opencode/AGENTS.md",
                    "Claude": delivery_root / ".claude/CLAUDE.md",
                    "Codex": delivery_root / ".codex/AGENTS.md",
                    "Grok": grok_policy_delivery,
                    "Claude work": work_claude_delivery,
                }
                retired_policy_markers = (
                    "## Questions and personal notes",
                    "appended shared Par policy governs conversational tone",
                    "The single highest-value thing you provide is the trap.",
                )
                for client, policy in policies.items():
                    if not policy.is_file() or not policy.read_text().strip():
                        raise SystemExit(f"{client} lacks an upstream-delivered policy: {policy}")
                    content = policy.read_text()
                    if any(marker in content for marker in retired_policy_markers):
                        raise SystemExit(f"{client} retains a retired local policy marker: {policy}")

                gentleman_style = rendered_root / ".claude/output-styles/gentleman.md"
                if not gentleman_style.is_file() or "name: Gentleman" not in gentleman_style.read_text():
                    raise SystemExit("Claude upstream Gentleman output style was not rendered")

                for relative in (".claude/settings.json", ".claude-work/settings.json"):
                    settings = json.loads((rendered_root / relative).read_text())
                    if settings.get("outputStyle") != "Gentleman":
                        raise SystemExit(f"Claude upstream Gentleman output style was not selected: {relative}")
                    retired_settings = (
                        "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS",
                        "ccstatusline",
                        "opus[1m]",
                        "dark-daltonized",
                        "agentPushNotifEnabled",
                    )
                    if any(marker in json.dumps(settings) for marker in retired_settings):
                        raise SystemExit(f"Claude retains a retired local setting: {relative}")

                for relative in (
                    ".claude/hooks/herdr-agent-state.sh",
                    ".codex/herdr-agent-state.sh",
                    ".config/opencode/plugins/herdr-agent-state.js",
                    ".pi/agent/extensions/herdr-agent-state.ts",
                ):
                    if (rendered_root / relative).exists():
                        raise SystemExit(f"retired custom Herdr asset remains rendered: {relative}")

                if policies["Grok"].read_text() != policies["OpenCode"].read_text():
                    raise SystemExit("Grok policy must be mapped from upstream OpenCode assets")

                for name in ("atlas", "aws", "clickup", "context7", "dbflux", "maestro", "obsidian", "penpot"):
                    if not (rendered_root / f".claude/mcp/{name}.json").is_file():
                        raise SystemExit(f"Claude MCP was not rendered: {name}")
                if not (rendered_root / ".config/opencode/opencode.json").is_file():
                    raise SystemExit("OpenCode MCP configuration was not rendered")
                if not (rendered_root / ".pi/agent/mcp.json").is_file():
                    raise SystemExit("Pi MCP configuration was not rendered")

                manifest = json.loads((rendered_root.parent / "manifest.json").read_text())
                resources = manifest["manifest"]["resources"]
                if not any(resource.get("component") == "engram" for resource in resources):
                    raise SystemExit("Engram upstream component provisioning was not rendered")
                PY

                touch $out
              '';

          atlas-desktop = functionalCheck "atlas-desktop" ./tests/atlas-desktop.nix {
            flake = flakeView;
          };

          gentle-pi-runtime-repair = functionalCheck "gentle-pi-runtime-repair" ./tests/gentle-pi-runtime-repair.nix {
            flake = flakeView;
            inherit pkgs;
          };

        }
        // deploy-rs.lib.x86_64-linux.deployChecks self.deploy;

      devShells.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.mkShell {
        DEVENV_TUI = "false";
        packages = with nixpkgs.legacyPackages.x86_64-linux; [
          nixpkgs.legacyPackages.x86_64-linux.deploy-rs
          devenv
          sops
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
