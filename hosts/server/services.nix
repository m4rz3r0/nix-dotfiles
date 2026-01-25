{ config, pkgs, lib, ... }: {
  imports = [ 
    ./containers.nix 
  ];

  # Automatic folder creation
  systemd.tmpfiles.rules = [
    "d /var/lib/media/descargas 0775 m4rz3r0 multimedia -"
    "d /var/lib/media/peliculas 0775 m4rz3r0 multimedia -"
    "d /var/lib/media/series    0775 m4rz3r0 multimedia -"
    "d /var/lib/jdownloader/config 0775 m4rz3r0 multimedia -"
  ];

  # Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 80 443 8096 ];
    allowedUDPPorts = [ 41641 1900 7359 ];
  };

  # Secrets
  sops.secrets.nextcloud_pass = { owner = "nextcloud"; };
  sops.secrets.vaultwarden_env = {};

  # Headscale (VPN Server)
  services.headscale = {
    enable = true;
    address = "0.0.0.0";
    port = 8080;
    settings = {
      server_url = "https://vpn.m4rz3r0.net";
      ip_prefixes = [ "100.64.0.0/10" ];
      dns = {
        magic_dns = true;
        base_domain = "m4rz3r0.internal";
        override_local_dns = true;
        nameservers.global = [ "1.1.1.1" "9.9.9.9" ];
        extra_records = [
          { name = "cloud.m4rz3r0.internal"; type = "A"; value = "100.64.0.1"; }
          { name = "vault.m4rz3r0.internal"; type = "A"; value = "100.64.0.1"; }
          { name = "jellyfin.m4rz3r0.internal"; type = "A"; value = "100.64.0.1"; }
          { name = "jd.m4rz3r0.internal"; type = "A"; value = "100.64.0.1"; }
          { name = "torrents.m4rz3r0.internal"; type = "A"; value = "100.64.0.1"; }
        ];
      };
    };
  };

  # Tailscale (VPN Client)
  services.tailscale = { enable = true; openFirewall = true; };

  # Caddy (Proxy)
  services.caddy = {
    enable = true;
    virtualHosts = {
      "vpn.m4rz3r0.net".extraConfig = "reverse_proxy 127.0.0.1:8080";
      
      "cloud.m4rz3r0.internal" = {
        listenAddresses = ["100.64.0.1"];
        extraConfig = "tls internal\nreverse_proxy 127.0.0.1:8081";
      };
      "vault.m4rz3r0.internal" = {
        listenAddresses = ["100.64.0.1"];
        extraConfig = "tls internal\nreverse_proxy 127.0.0.1:8222";
      };
      "jellyfin.m4rz3r0.internal" = {
        listenAddresses = ["100.64.0.1"];
        extraConfig = "tls internal\nreverse_proxy 127.0.0.1:8096";
      };
      "jd.m4rz3r0.internal" = {
        listenAddresses = ["100.64.0.1"];
        extraConfig = "tls internal\nreverse_proxy 127.0.0.1:5800";
      };
      "torrents.m4rz3r0.internal" = {
        listenAddresses = ["100.64.0.1"];
        extraConfig = "tls internal\nreverse_proxy 127.0.0.1:8085";
      };
    };
  };

  # Nginx (Nextcloud)
  services.nginx = { enable = true; defaultHTTPListenPort = 8081; defaultListenAddresses = [ "127.0.0.1" ]; };

  # Nextcloud
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud32;
    hostName = "cloud.m4rz3r0.internal";
    https = true;
    database.createLocally = true;
    configureRedis = true;
    maxUploadSize = "16G";
    phpOptions = {
      "memory_limit" = lib.mkForce "4G";
      "opcache.interned_strings_buffer" = "16";
      "upload_max_filesize" = "16G";
      "post_max_size" = "16G";
    };
    config = {
      adminpassFile = config.sops.secrets.nextcloud_pass.path;
      dbtype = "pgsql";
    };
    settings = { 
      trusted_proxies = [ "127.0.0.1" "::1" ];
      overwriteProtocol = "https";
      defaultPhoneRegion = "ES";
      maintenance_window_start = 1;
    };
    autoUpdateApps.enable = true;
  };

  # Jellyfin
  services.jellyfin = { enable = true; openFirewall = false; user = "m4rz3r0"; group = "multimedia"; };
  hardware.graphics = { enable = true; enable32Bit = true; };

  # Vaultwarden
  services.vaultwarden = {
    enable = true;
    environmentFile = config.sops.secrets.vaultwarden_env.path;
    config = {
      DOMAIN = "https://vault.m4rz3r0.internal";
      SIGNUPS_ALLOWED = false;
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;
    };
  };

  # qBittorrent
  systemd.services.qbittorrent = {
    description = "qBittorrent-nox";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = "m4rz3r0";
      Group = "multimedia";
      ExecStart = "${pkgs.qbittorrent-nox}/bin/qbittorrent-nox --webui-port=8085";
      Restart = "on-failure";
    };
  };
}
