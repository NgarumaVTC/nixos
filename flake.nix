{
  description = "Ngaruma VTC School Server Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, sops-nix }: {
    nixosConfigurations.nvtc1 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        sops-nix.nixosModules.sops
        ./hosts/nvtc1/hardware-configuration.nix
        ./hosts/nvtc1/configuration.nix
      ];
    };
  };
}
