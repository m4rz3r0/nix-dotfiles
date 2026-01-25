{
  description = "m4rz3r0 System Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-facter-modules.url = "github:nix-community/nixos-facter-modules";
  };

  outputs = { self, nixpkgs, disko, sops-nix, nixos-facter-modules, ... }: {
    nixosConfigurations = {

      # Server
      z3r0net-server = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          nixos-facter-modules.nixosModules.facter
          
          ./modules/common.nix
          ./modules/disks/standard.nix
          ./hosts/server/default.nix
          
          {
            config.facter.reportPath = 
              if builtins.pathExists ./hosts/server/facter.json then
                ./hosts/server/facter.json
              else
                throw "¡MISSING REPORT! Execute 'nixos-facter > hosts/server/facter.json' before install.";
          }
        ];
      };

      # Laptop
      z3r0net-tp = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          nixos-facter-modules.nixosModules.facter

          ./modules/common.nix
          ./modules/disks/standard.nix
          ./hosts/laptop/default.nix

          {
            config.facter.reportPath = 
              if builtins.pathExists ./hosts/laptop/facter.json then
                ./hosts/laptop/facter.json
              else
                throw "¡MISSING REPORT! Execute 'nixos-facter > hosts/laptop/facter.json' before install.";
          }
        ];
      };

      # PC
      z3r0net-pc = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          nixos-facter-modules.nixosModules.facter

          ./modules/common.nix
          ./modules/disks/dualboot.nix
          ./hosts/pc/default.nix

          {
            config.facter.reportPath = 
              if builtins.pathExists ./hosts/pc/facter.json then
                ./hosts/pc/facter.json
              else
                throw "¡MISSING REPORT! Execute 'nixos-facter > hosts/pc/facter.json' before install.";
          }
        ];
      };

    };
  };
}
