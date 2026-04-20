{
  description = "Your new nix config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim.url = "github:0xErwin1/nixvim";

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
      url = "github:0xErwin1/dbflux/dev";
    };

    niri-flake = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-desktop = {
      url = "github:aaddrick/claude-desktop-debian";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      inherit (self) outputs;

      overlays = {
        default = final: prev:
          (inputs.claude-desktop.overlays.default final prev)
          // {
            brave-origin-nightly = final.callPackage "${self}/pkgs/brave-origin-nightly" { };
            helium = final.callPackage "${self}/pkgs/helium" { };
            engram = final.callPackage "${self}/pkgs/engram" { };
            tuicr = final.callPackage "${self}/pkgs/tuicr" { };
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
          modules = [ ./hosts/epsilon ];
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
