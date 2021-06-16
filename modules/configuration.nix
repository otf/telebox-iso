{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.useDHCP = false;
  networking.interfaces.eno1.useDHCP = true;
  networking.interfaces.eno2.useDHCP = true;

  virtualisation.oci-containers.containers = {
    nginx-container = {
      image = "nginx-container";
      imageFile = pkgs.dockerTools.examples.nginx;
      ports = [ "80:80" ];
    };
  };

  system.stateVersion = "21.05";
}
