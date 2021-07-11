{ config, pkgs, ... }:

let
  configFile = builtins.toFile "configuration.nix" (builtins.readFile ./configuration.nix);
  hardwareConfigFile = builtins.toFile "hardware-configuration.nix" (builtins.readFile ./hardware-configuration.nix);
  bitwardenServerModuleFile = builtins.toFile "bitwarden-server.nix" (builtins.readFile ./bitwarden-server.nix);
  bitwardenServerImagesFile = builtins.toFile "bitwarden-server-images.nix" (builtins.readFile ./bitwarden-server-images.nix);
in {
  isoImage.isoBaseName = "telebox";
  isoImage.volumeID = "TELEBOX_ISO";

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

      # Create a RAID volume.
      mdadm --create /dev/md/imsm /dev/sd[a-b] --raid-devices 2 -e imsm
      mdadm --create /dev/md/md0 /dev/md/imsm --raid-devices 2 --level raid1 --assume-clean

      # Formatting
      mkfs.ext4 -F -L nixos /dev/nvme0n1p2
      mkfs.fat -F 32 -n boot /dev/nvme0n1p1
      mkfs.ext4 -F -L backups /dev/md/md0

      # Mount
      mount /dev/disk/by-label/nixos /mnt
      mkdir -p /mnt/boot
      mount /dev/disk/by-label/boot /mnt/boot
      mkdir -p /mnt/mnt/hdd
      mount /dev/disk/by-label/backups /mnt/mnt/hdd

      # Create a symlink for MSSQL backups.
      mkdir -p /mnt/var/opt/mssql
      mkdir -p /mnt/mnt/hdd/var/opt/mssql/backups
      ln -s /mnt/hdd/var/opt/mssql/backups /mnt/var/opt/mssql/backups

      # Install
      mkdir -p /mnt/etc/nixos
      cp ${configFile} /mnt/etc/nixos/configuration.nix
      cp ${hardwareConfigFile} /mnt/etc/nixos/hardware-configuration.nix
      cp ${bitwardenServerModuleFile} /mnt/etc/nixos/bitwarden-server.nix
      cp ${bitwardenServerImagesFile} /mnt/etc/nixos/bitwarden-server-images.nix

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
