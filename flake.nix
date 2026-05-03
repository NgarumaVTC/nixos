{
  description = "Ngaruma VTC School Server Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    nixosConfigurations.ngarumavtc1 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hosts/ngarumavtc1/hardware-configuration.nix
        ./hosts/ngarumavtc1/configuration.nix
      ];
    };
  };
}
