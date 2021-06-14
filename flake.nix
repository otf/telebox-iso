{
  description = "Installer iso image for Telebox.";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-21.05-small";
  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
    in {
      defaultPackage.${system} = 
        let 
          telebox = (import "${nixpkgs}/nixos/lib/eval-config.nix") {
            inherit system;
            modules = [
              "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
              ./modules/installation.nix
              ({ config, pkgs, lib, ... }: {
                isoImage.isoBaseName = "telebox";
                isoImage.volumeID = "TELEBOX_ISO";
              })
            ];
          };
        in
          telebox.config.system.build.isoImage;
    };
}

