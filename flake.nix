{
  description = "Installer iso image for Telebox.";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-21.05-small";
  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
      };
    in {
      checks.${system} = {
        test-machine = pkgs.nixosTest (import tests/machine.nix { inherit pkgs; });
        test-bitwarden-server = pkgs.nixosTest (import tests/bitwarden-server.nix { inherit pkgs; });
      };
      nixosConfigurations = {
        # Used with `nixos-rebuild switch --flake .#machine`
        machine = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./modules/configuration.nix
          ];
        };
        installer = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
            ./modules/installation.nix
          ];
        };
      };
      defaultPackage.${system} = 
        self.nixosConfigurations.installer.config.system.build.isoImage;
    };
}

