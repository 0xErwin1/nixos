{
  description = "Your new nix config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
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
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nix-flatpak,
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

      # Read wireguard local config at flake evaluation time (requires --impure).
      # Returns {} if the file does not exist, so builds work on machines without it.
      wireguardLocalPath = "/home/iperez/.ssh/wireguard/default.nix";
      wireguardLocal = if builtins.pathExists wireguardLocalPath then import wireguardLocalPath else { };
    in
    {
      inherit overlays;

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
      };

      devShells.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.mkShell {
        packages = with nixpkgs.legacyPackages.x86_64-linux; [
          nil
          nixfmt-rfc-style
        ];
      };
    };
}
