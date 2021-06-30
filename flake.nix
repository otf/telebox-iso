{
  description = "Installer iso image for Telebox.";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-21.05-small";
  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      checks.${system} = {
        test-machine = pkgs.nixosTest (import tests/machine.nix { inherit pkgs; });
        test-bitwarden = pkgs.nixosTest (import tests/bitwarden.nix { inherit pkgs; });
      };
      nixosConfigurations.machine = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./modules/configuration.nix
        ];
      };
      defaultPackage.${system} = 
        let 
          telebox = import "${nixpkgs}/nixos" {
            inherit system;
            configuration = { pkgs, ...}: {
              imports = [
                "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
                ./modules/installation.nix
              ];
              isoImage.isoBaseName = "telebox";
              isoImage.volumeID = "TELEBOX_ISO";
            };
          };
        in
          telebox.config.system.build.isoImage;
    };
}

