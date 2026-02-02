{ config, pkgs, ... }: {
  imports = [ ./services.nix ];

  networking.hostName = "z3r0net-server";

  # Network
  networking.networkmanager.enable = false;
  networking.useDHCP = false;

  networking.interfaces.enp3s0 = {
    useDHCP = false;
    ipv4.addresses = [{
      address = "192.168.1.13";
      prefixLength = 24;
    }];
  };

  networking.defaultGateway = "192.168.1.1";
  networking.nameservers = [ "1.1.1.1" "9.9.9.9" ]; # DNS Cloudflare/Quad9

  # DDNS
  sops.secrets."cloudflare_token" = { };
  sops.secrets."zone_identifier" = { };
  sops.templates."ddns-config.json" = {
    content = ''
      {
        "settings": [
          {
            "provider": "cloudflare",
            "zone_identifier": "${config.sops.placeholder.zone_identifier}",
            "domain": "vpn.m4rz3r0.net",
            "ttl": 600,
            "token": "${config.sops.placeholder.cloudflare_token}",
            "ip_version": "ipv4",
            "ipv6_suffix": ""
          }
        ]
      }
    '';
    mode = "0444";
  };

  services.ddns-updater = {
    enable = true;
    environment = {
      SERVER_ENABLED="no";
      CONFIG_FILEPATH = config.sops.templates."ddns-config.json".path;
      PERIOD = "5m";
    };
  };

  # SSH
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "prohibit-password"; # Solo llaves
  };

  # Boot and TPM
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Initrd with systemd mandatory for TPM2
  boot.initrd.systemd.enable = true;
  # SSH at startup
  boot.initrd.network.enable = true;

  # Automatic decrypt
  boot.initrd.luks.devices."crypted".crypttabExtraOpts = [ "tpm2-device=auto" ];

  # Laptop server mode
  services.logind.settings.Login.HandleLidSwitch = "ignore";
  systemd.targets.sleep.enable = false;
  services.thermald.enable = true;

  # === Backups (Restic) ===
  #sops.secrets.restic_pass = {};

  #services.restic.backups.daily = {
  #  initialize = true;
  #  passwordFile = config.sops.secrets.restic_pass.path;
  #  repository = "s3:s3.us-west-000.backblazeb2.com/m4rz3r0-backup"; # Ajusta esto
  #  paths = [ "/var/lib/nextcloud" "/var/lib/jellyfin" ];
  #  timerConfig.OnCalendar = "03:00";
  #};
}
