{
  description = "Installer iso image for Telebox.";
  inputs.nixos.url = "github:nixos/nixpkgs/nixos-20.09";
  outputs = { self, nixos }: {
    defaultPackage."x86_64-linux" =
      with (import "${nixos}/nixos/lib/eval-config.nix") {
        system = "x86_64-linux";
        modules = [
          "${nixos}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          ({ pkgs, lib, ... }: {
            systemd.services.installation = {
              description = "Installation";
              wantedBy = [ "multi-user.target" ];
              after = [ "getty.target" "network.target" ];
              conflicts = [ "getty@tty1.service" ];
              script = with pkgs; ''
                ${kmod}/bin/modprobe pcspkr
                ${beep}/bin/beep -f 2000;
                ${beep}/bin/beep -f 1000;
              '';
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = "yes";
                StarndardInput = "tty-force";
                StarndardOutput = "inherit";
                StarndardError = "inherit";
                TTYReset = "yes";
                TTYVHangup = "yes";
              };
            };
          })
        ];
      };
      config.system.build.isoImage;
  };
}

