{ pkgs, ... }:

{
  nodes = {
    server = {
      imports = [ ../modules/bitwarden-server.nix ];

      virtualisation.diskSize = 12 * 1024;
      virtualisation.memorySize = 4 * 1024;

      services.bitwardenServer.enable = true;
      services.bitwardenServer.isDevelopment = true;
      services.bitwardenServer.domain = "server";
      services.bitwardenServer.databasePassword = "RANDOM_DATABASE_PASSWORD";
    };

    client = { };
  };

  testScript = ''
    start_all()

    with subtest('Users should access the bitwarden www server'):
      server.wait_for_unit('bitwarden-server.target')
      server.wait_for_open_port(443)
      assert 'Bitwarden Web Vault' in client.succeed('curl --location --insecure https://server/')
  '';
}
