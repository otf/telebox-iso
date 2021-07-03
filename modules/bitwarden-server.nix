{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.bitwardenServer;
  coreVersion = "1.41.4";
  webVersion = "2.21.0";
  uid = 1000;
  gid = 1000;
  user = "bitwarden";
  group = "bitwarden";

  identityCertificate = pkgs.runCommand "generate-identity-certificate" { } ''
    mkdir -p $out/ssl
    ${pkgs.openssl}/bin/openssl req -x509 -newkey rsa:4096 -sha256 -nodes -keyout identity.key \
          -out identity.crt -subj "/CN=Bitwarden IdentityServer" -days 36500

    ${pkgs.openssl}/bin/openssl pkcs12 -export -out $out/ssl/identity.pfx -inkey identity.key \
          -in identity.crt -certfile identity.crt -passout pass:IDENTITY_CERT_PASSWORD
  '';

  selfSignedCertificate = pkgs.runCommand "generate-self-signed-certificate" { } ''
    mkdir -p $out/ssl
    ${pkgs.openssl}/bin/openssl req -x509 -newkey rsa:4096 -sha256 -nodes -days 3650 \
          -keyout $out/ssl/private.key \
          -out $out/ssl/certificate.crt \
          -reqexts SAN -extensions SAN \
          -config <(cat ${pkgs.openssl.out}/etc/ssl/openssl.cnf <(printf '[SAN]\nsubjectAltName=DNS:${cfg.domain}\nbasicConstraints=CA:true')) \
          -subj "/C=US/ST=California/L=Santa Barbara/O=Bitwarden Inc./OU=Bitwarden/CN=${cfg.domain}"
  '';

in {
  options.services.bitwardenServer = with types; {

    enable = mkEnableOption "bitwarden server";

    installationId = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "00000000-0000-0000-0000-000000000000";
      description = ''
        Specify Installation ID.
      '';
    };

    installationKey = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "xxxxxxxxxxxxxxxxxxxx";
      description = ''
        Specify Installation Key.
      '';
    };

    isDevelopment = mkOption {
      type = types.bool;
      default = false;
      example = "false";
      description = ''
        Specify whether the environment is development.
      '';
    };

    domain = mkOption {
      type = types.str;
      example = "bitwarden.example.com";
      description = ''
        Specify which domain.
      '';
    };

    databasePassword = mkOption {
      type = types.str;
      example = "RANDOM_DATABASE_PASSWORD";
      description = ''
        Specify database password..
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = !cfg.isDevelopment -> cfg.installationId != null && cfg.installationKey != null;
        message = ''
          `installationId` and `installationKey` should be specified if `isDevelopment` were false.
        '';
      }
    ];

    users = {
      groups.${group} = {
        inherit gid;
      };
      users.${user} = {
        inherit uid group;
        isSystemUser = true;
        extraGroups = [ "docker" "wheel" ];
      };
    };

    environment.etc = {

      "bitwarden/env/uid.env" = {
        mode = "0600";
        text = ''
          LOCAL_UID=${toString uid}
          LOCAL_GID=${toString gid}
        '';
      };

      "bitwarden/env/mssql.env" = {
        mode = "0600";
        text = ''
          ACCEPT_EULA=Y
          MSSQL_PID=Express
          SA_PASSWORD=${cfg.databasePassword}
        '';
      };

      "bitwarden/env/global.env" = {
        mode = "0600";
        text = ''
          ${lib.optionalString cfg.isDevelopment "ASPNETCORE_ENVIRONMENT=Development"}
          ${lib.optionalString (!cfg.isDevelopment) "ASPNETCORE_ENVIRONMENT=Production"}
          globalSettings__selfHosted=true
          globalSettings__baseServiceUri__vault=http://localhost
          globalSettings__pushRelayBaseUri=https://push.bitwarden.com
        '';
      };

      "bitwarden/env/global.override.env" = {
        mode = "0600";
        text = ''
          globalSettings__baseServiceUri__vault=https://${cfg.domain}
          globalSettings__sqlServer__connectionString="Data Source=tcp:mssql,1433;Initial Catalog=vault;Persist Security Info=False;User ID=sa;Password=${cfg.databasePassword};MultipleActiveResultSets=False;Connect Timeout=30;Encrypt=True;TrustServerCertificate=True"
          globalSettings__identityServer__certificatePassword=IDENTITY_CERT_PASSWORD
          globalSettings__internalIdentityKey=RANDOM_IDENTITY_KEY
          globalSettings__oidcIdentityClientKey=RANDOM_IDENTITY_KEY
          globalSettings__duo__aKey=RANDOM_DUO_AKEY
          ${lib.optionalString (cfg.installationId != null)
          "globalSettings__installation__id=${cfg.installationId}"}
          ${lib.optionalString (cfg.installationKey != null)
          "globalSettings__installation__key=${cfg.installationKey}"}
          globalSettings__yubico__clientId=REPLACE
          globalSettings__yubico__key=REPLACE
          globalSettings__mail__replyToEmail=no-reply@bitwarden.example.com
          globalSettings__mail__smtp__host=REPLACE
          globalSettings__mail__smtp__port=587
          globalSettings__mail__smtp__ssl=false
          globalSettings__mail__smtp__username=REPLACE
          globalSettings__mail__smtp__password=REPLACE
          globalSettings__disableUserRegistration=false
          globalSettings__hibpApiKey=REPLACE
          adminSettings__admins=
        '';
      };

      "bitwarden/web/app-id.json" = {
        mode = "0600";
        text = ''
          {
            "trustedFacets": [
              {
                "version": {
                  "major": 1,
                  "minor": 0
                },
                "ids": [
                  "https://${cfg.domain}",
                  "ios:bundle-id:com.8bit.bitwarden",
                  "android:apk-key-hash:dUGFzUzf3lmHSLBDBIv+WaFyZMI"
                ]
              }
            ]
          }
        '';
      };

      "bitwarden/nginx/default.conf" = {
        mode = "0600";
        text = ''
          #######################################################################
          # WARNING: This file is generated. Do not make changes to this file.  #
          # They will be overwritten on update. You can manage various settings #
          # used in this file from the ./bwdata/config.yml file for your        #
          # installation.                                                       #
          #######################################################################

          server {
            listen 8080 default_server;
            listen [::]:8080 default_server;
            server_name ${cfg.domain};

            return 301 https://${cfg.domain}$request_uri;
          }

          server {
            listen 8443 ssl http2;
            listen [::]:8443 ssl http2;
            server_name ${cfg.domain};

            ssl_certificate /etc/ssl/self/${cfg.domain}/certificate.crt;
            ssl_certificate_key /etc/ssl/self/${cfg.domain}/private.key;
            ssl_session_timeout 30m;
            ssl_session_cache shared:SSL:20m;
            ssl_session_tickets off;

            ssl_protocols TLSv1.2;
            ssl_ciphers "ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256";
            # Enables server-side protection from BEAST attacks
            ssl_prefer_server_ciphers on;

            include /etc/nginx/security-headers-ssl.conf;
            include /etc/nginx/security-headers.conf;

            location / {
              proxy_pass http://web:5000/;
              include /etc/nginx/security-headers-ssl.conf;
              include /etc/nginx/security-headers.conf;
              add_header Content-Security-Policy "default-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https://haveibeenpwned.com https://www.gravatar.com; child-src 'self' https://*.duosecurity.com https://*.duofederal.com; frame-src 'self' https://*.duosecurity.com https://*.duofederal.com; connect-src 'self' wss://${cfg.domain} https://api.pwnedpasswords.com https://2fa.directory; object-src 'self' blob:;";
              add_header X-Frame-Options SAMEORIGIN;
              add_header X-Robots-Tag "noindex, nofollow";
            }

            location /alive {
              return 200 'alive';
              add_header Content-Type text/plain;
            }

            location = /app-id.json {
              proxy_pass http://web:5000/app-id.json;
              include /etc/nginx/security-headers-ssl.conf;
              include /etc/nginx/security-headers.conf;
              proxy_hide_header Content-Type;
              add_header Content-Type $fido_content_type;
            }

            location = /duo-connector.html {
              proxy_pass http://web:5000/duo-connector.html;
            }

            location = /u2f-connector.html {
              proxy_pass http://web:5000/u2f-connector.html;
            }

            location = /webauthn-connector.html {
              proxy_pass http://web:5000/webauthn-connector.html;
            }

            location = /webauthn-fallback-connector.html {
              proxy_pass http://web:5000/webauthn-fallback-connector.html;
            }

            location = /sso-connector.html {
              proxy_pass http://web:5000/sso-connector.html;
            }

            location /attachments/ {
              proxy_pass http://attachments:5000/;
            }

            location /api/ {
              proxy_pass http://api:5000/;
            }

            location /icons/ {
              proxy_pass http://icons:5000/;
            }

            location /notifications/ {
              proxy_pass http://notifications:5000/;
            }

            location /notifications/hub {
              proxy_pass http://notifications:5000/hub;
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection $http_connection;
            }

            location /events/ {
              proxy_pass http://events:5000/;
            }

            location /sso {
              proxy_pass http://sso:5000;
              include /etc/nginx/security-headers-ssl.conf;
              include /etc/nginx/security-headers.conf;
              add_header X-Frame-Options SAMEORIGIN;
            }

            location /identity {
              proxy_pass http://identity:5000;
              include /etc/nginx/security-headers-ssl.conf;
              include /etc/nginx/security-headers.conf;
              add_header X-Frame-Options SAMEORIGIN;
            }

            location /admin {
              proxy_pass http://admin:5000;
              include /etc/nginx/security-headers-ssl.conf;
              include /etc/nginx/security-headers.conf;
              add_header X-Frame-Options SAMEORIGIN;
            }

            location /portal {
              proxy_pass http://portal:5000;
              include /etc/nginx/security-headers-ssl.conf;
              include /etc/nginx/security-headers.conf;
              add_header X-Frame-Options SAMEORIGIN;
            }
          }
        '';
      };

      "bitwarden/identity/identity.pfx" = {
        mode = "0600";
        source = "${identityCertificate}/ssl/identity.pfx";
      };

      "bitwarden/ssl/self/${cfg.domain}/private.key" = {
        mode = "0600";
        source = "${selfSignedCertificate}/ssl/private.key";
      };

      "bitwarden/ssl/self/${cfg.domain}/certificate.crt" = {
        mode = "0600";
        source = "${selfSignedCertificate}/ssl/certificate.crt";
      };

    };

    systemd.targets.bitwarden-server = {
      description = "bitwarden server target";
      wantedBy = [ "multi-user.target" ];
      requires = [
        "docker-bitwarden-network.service"
        "docker-bitwarden-mssql.service"
        "docker-bitwarden-web.service"
        "docker-bitwarden-attachments.service"
        "docker-bitwarden-api.service"
        "docker-bitwarden-identity.service"
        "docker-bitwarden-sso.service"
        "docker-bitwarden-admin.service"
        "docker-bitwarden-portal.service"
        "docker-bitwarden-icons.service"
        "docker-bitwarden-notifications.service"
        "docker-bitwarden-events.service"
        "docker-bitwarden-nginx.service"
      ];
    };

    systemd.services.docker-bitwarden-network = {
      description = "Docker bridge network";
      wantedBy = [ "multi-user.target" ];
      after = [ "docker.service" ];
      before = [
        "docker-bitwarden-mssql.service"
        "docker-bitwarden-web.service"
        "docker-bitwarden-attachments.service"
        "docker-bitwarden-api.service"
        "docker-bitwarden-identity.service"
        "docker-bitwarden-sso.service"
        "docker-bitwarden-admin.service"
        "docker-bitwarden-portal.service"
        "docker-bitwarden-icons.service"
        "docker-bitwarden-notifications.service"
        "docker-bitwarden-events.service"
        "docker-bitwarden-nginx.service"
      ];
      serviceConfig = {
        ExecStartPre = "-${pkgs.docker}/bin/docker network rm bitwarden-network";
        ExecStart = "${pkgs.docker}/bin/docker network create bitwarden-network";
        ExecStop = "${pkgs.docker}/bin/docker network rm bitwarden-network";
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };

    virtualisation.oci-containers.containers = {
      bitwarden-mssql =  {
        image = "bitwarden/mssql:${coreVersion}";
        imageFile = pkgs.bitwardenServerImages.mssql;
        volumes = [
          "/var/opt/mssql/data:/var/opt/mssql/data"
          "/var/opt/bitwarden/logs/mssql:/var/opt/mssql/log"
          "/var/opt/mssql/backups:/etc/bitwarden/mssql/backups"
        ];
        environmentFiles = [
          "/etc/bitwarden/env/uid.env"
          "/etc/bitwarden/env/mssql.env"
        ];
        extraOptions = [
          "--net-alias=mssql"
          "--network=bitwarden-network"
        ];
      };

      bitwarden-web =  {
        image = "bitwarden/web:${webVersion}";
        imageFile = pkgs.bitwardenServerImages.web;
        volumes = [
          "/etc/bitwarden/web:/etc/bitwarden/web"
        ];
        environmentFiles = [
          "/etc/bitwarden/env/global.env"
          "/etc/bitwarden/env/uid.env"
        ];
        extraOptions = [
          "--net-alias=web"
          "--network=bitwarden-network"
        ];
      };

      bitwarden-attachments =  {
        image = "bitwarden/attachments:${coreVersion}";
        imageFile = pkgs.bitwardenServerImages.attachments;
        volumes = [
          "/var/opt/bitwarden/core/attachments:/etc/bitwarden/core/attachments"
        ];
        environmentFiles = [
          "/etc/bitwarden/env/global.env"
          "/etc/bitwarden/env/uid.env"
        ];
        extraOptions = [
          "--net-alias=attachments"
          "--network=bitwarden-network"
        ];
      };

      bitwarden-api =  {
        image = "bitwarden/api:${coreVersion}";
        imageFile = pkgs.bitwardenServerImages.api;
        volumes = [
          "/var/opt/bitwarden/core:/etc/bitwarden/core"
          "/var/opt/bitwarden/logs/api:/etc/bitwarden/logs"
        ];
        environmentFiles = [
          "/etc/bitwarden/env/global.env"
          "/etc/bitwarden/env/uid.env"
          "/etc/bitwarden/env/global.override.env"
        ];
        extraOptions = [
          "--net-alias=api"
          "--network=bitwarden-network"
        ];
      };

      bitwarden-identity =  {
        image = "bitwarden/identity:${coreVersion}";
        imageFile = pkgs.bitwardenServerImages.identity;
        volumes = [
          "/etc/bitwarden/identity:/etc/bitwarden/identity"
          "/var/opt/bitwarden/core:/etc/bitwarden/core"
          "/var/opt/bitwarden/logs/identity:/etc/bitwarden/logs"
        ];
        environmentFiles = [
          "/etc/bitwarden/env/global.env"
          "/etc/bitwarden/env/uid.env"
          "/etc/bitwarden/env/global.override.env"
        ];
        extraOptions = [
          "--net-alias=identity"
          "--network=bitwarden-network"
        ];
      };

      bitwarden-sso =  {
        image = "bitwarden/sso:${coreVersion}";
        imageFile = pkgs.bitwardenServerImages.sso;
        volumes = [
          "${identityCertificate}/ssl:/etc/bitwarden/identity"
          "/var/opt/bitwarden/core:/etc/bitwarden/core"
          "/var/opt/bitwarden/logs/sso:/etc/bitwarden/logs"
        ];
        environmentFiles = [
          "/etc/bitwarden/env/global.env"
          "/etc/bitwarden/env/uid.env"
          "/etc/bitwarden/env/global.override.env"
        ];
        extraOptions = [
          "--net-alias=sso"
          "--network=bitwarden-network"
        ];
      };

      bitwarden-admin =  {
        image = "bitwarden/admin:${coreVersion}";
        imageFile = pkgs.bitwardenServerImages.admin;
        dependsOn = [
          "bitwarden-mssql"
        ];
        volumes = [
          "/var/opt/bitwarden/core:/etc/bitwarden/core"
          "/var/opt/bitwarden/logs/admin:/etc/bitwarden/logs"
        ];
        environmentFiles = [
          "/etc/bitwarden/env/global.env"
          "/etc/bitwarden/env/uid.env"
          "/etc/bitwarden/env/global.override.env"
        ];
        extraOptions = [
          "--net-alias=admin"
          "--network=bitwarden-network"
        ];
      };

      bitwarden-portal =  {
        image = "bitwarden/portal:${coreVersion}";
        imageFile = pkgs.bitwardenServerImages.portal;
        dependsOn = [
          "bitwarden-mssql"
        ];
        volumes = [
          "/var/opt/bitwarden/core:/etc/bitwarden/core"
          "/var/opt/bitwarden/logs/portal:/etc/bitwarden/logs"
        ];
        environmentFiles = [
          "/etc/bitwarden/env/global.env"
          "/etc/bitwarden/env/uid.env"
          "/etc/bitwarden/env/global.override.env"
        ];
        extraOptions = [
          "--net-alias=portal"
          "--network=bitwarden-network"
        ];
      };

      bitwarden-icons =  {
        image = "bitwarden/icons:${coreVersion}";
        imageFile = pkgs.bitwardenServerImages.icons;
        volumes = [
          "/var/opt/bitwarden/logs/icons:/etc/bitwarden/logs"
        ];
        environmentFiles = [
          "/etc/bitwarden/env/global.env"
          "/etc/bitwarden/env/uid.env"
        ];
        extraOptions = [
          "--net-alias=icons"
          "--network=bitwarden-network"
        ];
      };

      bitwarden-notifications =  {
        image = "bitwarden/notifications:${coreVersion}";
        imageFile = pkgs.bitwardenServerImages.notifications;
        volumes = [
          "/var/opt/bitwarden/logs/notifications:/etc/bitwarden/logs"
        ];
        environmentFiles = [
          "/etc/bitwarden/env/global.env"
          "/etc/bitwarden/env/uid.env"
          "/etc/bitwarden/env/global.override.env"
        ];
        extraOptions = [
          "--net-alias=notifications"
          "--network=bitwarden-network"
        ];
      };

      bitwarden-events =  {
        image = "bitwarden/events:${coreVersion}";
        imageFile = pkgs.bitwardenServerImages.events;
        volumes = [
          "/var/opt/bitwarden/logs/events:/etc/bitwarden/logs"
        ];
        environmentFiles = [
          "/etc/bitwarden/env/global.env"
          "/etc/bitwarden/env/uid.env"
          "/etc/bitwarden/env/global.override.env"
        ];
        extraOptions = [
          "--net-alias=events"
          "--network=bitwarden-network"
        ];
      };

      bitwarden-nginx =  {
        image = "bitwarden/nginx:${coreVersion}";
        imageFile = pkgs.bitwardenServerImages.nginx;
        dependsOn = [
          "bitwarden-web"
          "bitwarden-admin"
          "bitwarden-api"
          "bitwarden-identity"
        ];
        ports = [
          "80:8080"
          "443:8443"
        ];
        volumes = [
          "/etc/bitwarden/nginx:/etc/bitwarden/nginx"
          "/etc/bitwarden/ssl:/etc/ssl"
          "/var/opt/bitwarden/logs/nginx:/var/log/nginx"
        ];
        environmentFiles = [
          "/etc/bitwarden/env/uid.env"
        ];
        extraOptions = [
          "--net-alias=nginx"
          "--network=bitwarden-network"
        ];
      };

    };
  };
}
