{ config, pkgs, ... }: {
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;
  time.timeZone = "Europe/Madrid";
  i18n.defaultLocale = "es_ES.UTF-8";

  # Global SOPS
  sops.defaultSopsFile = ../secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.age.keyFile = "/var/lib/sops-nix/keys.txt";

  # User secrets
  sops.secrets.user_pass_hash.neededForUsers = true;

  users.groups.multimedia = {};
  users.users.m4rz3r0 = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "video" "render" "multimedia" "podman" "adbusers" ];
    hashedPasswordFile = config.sops.secrets.user_pass_hash.path;
    openssh.authorizedKeys.keys = [
       "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKhFjUYq3Y9E9449DGulPqh9XPSU0cv76U4iINqMyN69"
    ];
    shell = pkgs.fish;
  };

  programs.fish.enable = true;
  services.tailscale.enable = true;
  environment.systemPackages = with pkgs; [ git wget btop ];
  system.stateVersion = "25.11";
}
