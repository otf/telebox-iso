{
  machine = import ../modules/configuration.nix;

  testScript =
    ''
    with subtest("NixOS version should be 21.05"):
      assert "21.05" in machine.succeed("nixos-version")
    '';
}
