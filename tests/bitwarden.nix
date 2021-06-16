{ pkgs, ... }:

{
  nodes = {
    server = import ../modules/configuration.nix;
    client = { };
  };

  testScript =
    ''
    start_all()
    server.wait_until_succeeds("docker ps | grep nginx-container")

    with subtest("Users should access the bitwarden www server"):
      assert "Hello from NGINX" in client.succeed("${pkgs.curl}/bin/curl http://server")
    '';
}
