{
  description = "Installer iso image for Telebox.";
  inputs.nixos.url = "github:nixos/nixpkgs/nixos-unstable";
  outputs = { self, nixos }: {
    defaultPackage."x86_64-linux" =
      with (import "${nixos}/nixos/lib/eval-config.nix") {
        system = "x86_64-linux";
        modules = [
          "${nixos}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        ];
      };
      config.system.build.isoImage;
  };
}

