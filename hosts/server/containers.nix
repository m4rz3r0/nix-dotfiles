{ config, pkgs, ... }: {

  # Podman
  virtualisation.podman = {
    enable = true;
    dockerCompat = true; # Alias docker=podman
    defaultNetwork.settings.dns_enabled = true;
  };

  # OCI backend
  virtualisation.oci-containers.backend = "podman";

  # Container defs
  virtualisation.oci-containers.containers = {
    
    # JDownloader 2
    jdownloader = {
      image = "jlesage/jdownloader-2";
      autoStart = true;
      ports = [ "5800:5800" ]; # WebUI
      volumes = [
        "/var/lib/jdownloader/config:/config:rw"
        "/var/lib/media:/output:rw"
      ];
      environment = {
        "USER_ID" = "1000"; # User ID
        "GROUP_ID" = "1000"; 
        "dark_mode" = "1";
      };
    };
  };
}
