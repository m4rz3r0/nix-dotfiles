{ config, pkgs, inputs, ... }: {

  imports = [
    ../../modules/common.nix
    inputs.home-manager.nixosModules.home-manager
  ];

  # ==========================================
  # Boot and kernel
  # ==========================================
  # Hardened kernel for extra security
  boot.kernelPackages = pkgs.linuxPackages_hardened;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Restrict unprivileged user namespaces
  boot.kernel.sysctl."kernel.unprivileged_userns_clone" = 1;

  # ==========================================
  # Networking
  # ==========================================
  networking.hostName = "z3r0net-tp";
  networking.networkmanager.enable = true;

  # Secure DNS (Quad9 via TLS)
  services.resolved = {
    enable = true;
    settings = {
      Resolve = {
        DNS = "9.9.9.9#dns.quad9.net";
        DNSOverTLS = "true";
        DNSSEC = "allow-downgrade";
        Domains = [ "~." ];
        FallbackDNS = [ "149.112.112.112" ];
      };
    };
  };

  # ==========================================
  # Desktop (GNOME)
  # ==========================================
  services.xserver = {
    enable = true;
    xkb = { layout = "es"; variant = "winkeys"; };
  };

  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Remove unused default GNOME applications
  environment.gnome.excludePackages = with pkgs; [
    cheese evince geary gnome-backgrounds gnome-calendar
    gnome-characters gnome-clocks gnome-connections gnome-contacts
    gnome-font-viewer gnome-logs gnome-maps gnome-music gnome-online-accounts
    gnome-photos gnome-tour gnome-user-docs gnome-weather snapshot totem yelp
    gnome-calculator gnome-console gnome-text-editor baobab
    gnome-initial-setup simple-scan
  ];

  # Nautilus quick preview
  services.gnome.sushi.enable = true;

  # Nautilus open with terminal
  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "alacritty";
  };

  # Required for GNOME settings daemon
  services.udev.packages = with pkgs; [ gnome-settings-daemon ];

  # ==========================================
  # Hardware and services
  # ==========================================
  # Audio configuration (Pipewire)
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Biometric authentication and AppArmor
  services.fprintd.enable = true;
  security.apparmor.enable = true;

  # Additional services
  services.fwupd.enable = true;
  services.flatpak.enable = true;
  services.printing.enable = false;

  # ==========================================
  # Home Manager integration
  # ==========================================
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    users.m4rz3r0 = import ./home.nix;
  };
}
