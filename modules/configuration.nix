{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./bitwarden-server.nix
  ] ++ lib.optional (builtins.pathExists ./bitwarden-server-configuration.nix) ./bitwarden-server-configuration.nix;

  nix = {
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.useDHCP = false;
  networking.interfaces.eno1.useDHCP = true;
  networking.interfaces.eno2.useDHCP = true;

  system.stateVersion = "21.05";
}
