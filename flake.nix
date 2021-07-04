{
  description = "Installer iso image for Telebox.";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-21.05-small";
  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ self.overlay ];
      };
    in {
      overlay = final: prev: {
        bitwardenServerImages = import ./modules/bitwarden-server-images.nix {
          inherit (pkgs.dockerTools) pullImage;
        };
      };
      nixosModules = {
        bitwardenServer = import ./modules/bitwarden-server.nix;
      };
      checks.${system} = {
        test-machine = pkgs.nixosTest (import tests/machine.nix { inherit pkgs; });
        test-bitwarden-server = pkgs.nixosTest (import tests/bitwarden-server.nix { inherit pkgs; });
      };
      nixosConfigurations = {
        # Used with `nixos-rebuild switch --flake .#machine`
        machine = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            { nixpkgs.overlays = [ self.overlay ]; }
            ./modules/configuration.nix
            self.nixosModules.bitwardenServer
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

