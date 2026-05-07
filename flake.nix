{
  description = "Ngaruma VTC School Server Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, sops-nix }: {
    nixosConfigurations.ngarumavtc1 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        sops-nix.nixosModules.sops
        ./hosts/ngarumavtc1/hardware-configuration.nix
        ./hosts/ngarumavtc1/configuration.nix
      ];
    };
  };
}
