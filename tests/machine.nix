{ pkgs, ... }:

{
  machine = import ../modules/configuration.nix;

  testScript = { nodes, ...}: let
      machineSystem = nodes.machine.config.system.build.toplevel;

      # Ensures failures pass through using pipefail, otherwise failing to
      # switch-to-configuration is hidden by the success of `tee`.
      stderrRunner = pkgs.writeScript "stderr-runner" ''
        #! ${pkgs.stdenv.shell}
        set -e
        set -o pipefail
        exec env -i "$@" | tee /dev/stderr
      '';
    in ''
      with subtest("NixOS version should be 21.05"):
        assert "21.05" in machine.succeed("nixos-version")

      with subtest("NixOS system should be able to switch"):
        machine.succeed("${stderrRunner} ${machineSystem}/bin/switch-to-configuration test")
    '';
}
