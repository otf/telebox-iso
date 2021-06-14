{ config, pkgs, ... }:

let
  configFile = builtins.toFile "configuration.nix" (builtins.readFile ./configuration.nix);
  hardwareConfigFile = builtins.toFile "hardware-configuration.nix" (builtins.readFile ./hardware-configuration.nix);
in {
  systemd.services.installation = {
    description = "Installation";
    wantedBy = [ "multi-user.target" ];
    after = [ "getty.target" "nscd.service" ];
    conflicts = [ "getty@tty1.service" ];
    script = with pkgs; ''
      set -euxo pipefail

      # Partitioning
      wipefs -fa /dev/nvme0n1
      parted -s /dev/nvme0n1 -- mklabel gpt
      parted -s /dev/nvme0n1 -- mkpart ESP fat32 1MiB 512MiB
      parted -s /dev/nvme0n1 -- set 1 esp on
      parted -s /dev/nvme0n1 -- mkpart primary ext4 512MiB 100%

      # Formatting
      mkfs.ext4 -F -L nixos /dev/nvme0n1p2
      mkfs.fat -F 32 -n boot /dev/nvme0n1p1

      # Mount
      mount /dev/disk/by-label/nixos /mnt
      mkdir -p /mnt/boot
      mount /dev/disk/by-label/boot /mnt/boot

      # Install
      mkdir -p /mnt/etc/nixos
      cp ${configFile} /mnt/etc/nixos/configuration.nix
      cp ${hardwareConfigFile} /mnt/etc/nixos/hardware-configuration.nix
      ${config.system.build.nixos-install}/bin/nixos-install --no-root-passwd
      reboot
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
    path = [ "/run/current-system/sw" ];
    environment = config.nix.envVars // {
      inherit (config.environment.sessionVariables) NIX_PATH;
      HOME = "/root";
    };
  };
}
