{
  description = "Your new nix config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim.url = "gitlab:0xErwin/nixvim";

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
      lib = nixpkgs.lib // home-manager.lib;

      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      pkgsFor = lib.genAttrs systems (
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        }
      );

      forEachSystem = f: lib.genAttrs systems (system: f pkgsFor.${system});

      nixosEpsilon = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs outputs;
        };
        modules = [ ./hosts/epsilon ];
      };

      hmDelta = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = {
          inherit inputs outputs;
        };
        modules = [ ./home-manager/delta ];
      };

      hmEpsilon = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = {
          inherit inputs outputs;
        };
        modules = [ ./home-manager/epsilon ];
      };
    in
    {
      inherit lib;

      devShells = forEachSystem (pkgs: import ./shell.nix { inherit pkgs; });
      packages = forEachSystem (pkgs: import ./pkgs { inherit pkgs inputs; });

      nixosConfigurations = {
        epsilon = nixosEpsilon;
      };

      homeConfigurations = {
        "iperez@delta" = hmDelta;
        "iperez@epsilon" = hmEpsilon;
      };

      checks = forEachSystem (
        pkgs:
        lib.optionalAttrs (pkgs.system == "x86_64-linux") {
          eval-nixos-epsilon = pkgs.writeText "eval-nixos-epsilon" nixosEpsilon.config.system.build.toplevel.drvPath;
          eval-home-delta = pkgs.writeText "eval-home-delta" hmDelta.activationPackage.drvPath;
          eval-home-epsilon = pkgs.writeText "eval-home-epsilon" hmEpsilon.activationPackage.drvPath;
        }
      );
    };
}
