{
  description = "Installer iso image for Telebox.";
  inputs.nixos.url = "github:nixos/nixpkgs/nixos-unstable";
  outputs = { self, nixos }: {
    nixosConfigurations = let
      # Shared base configuration.
      teleboxBase = {
        system = "x86_64-linux";
        modules = [
          # Common system modules ...
        ];
      };
    in {
      teleboxIso = nixos.lib.nixosSystem {
        inherit (teleboxBase) system;
        modules = teleboxBase.modules ++ [
          "${nixos}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        ];
      };

      telebox = nixos.lib.nixosSystem {
        inherit (teleboxBase) system;
        modules = teleboxBase.modules ++ [
          # Modules for installed systems only.
        ];
      };
    };
  };
}

