{
  description = "Build Dockerfile/Containerfile with Nix.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in
    {
      buildContainerFile = import ./build-containerfile.nix;

      packages.x86_64-linux = {
        cowsay-example = self.buildContainerFile
          {
            inherit pkgs;
            name = "cowsay";
            tag = "test";
            script = ''
              FROM debian:12-slim
              ARG MESSAGE=none
              RUN apt-get update && apt-get install -y cowsay
              RUN /usr/games/cowthink ''${MESSAGE}
            '';
            extraArgs = [ "--build-arg MESSAGE='Image is ready !'" ];
            vmMemorySize = 1024;
            vmDiskSize = 2048;
          };

        sl-example = self.buildContainerFile
          {
            inherit pkgs;
            name = "sl";
            tag = "test";
            script = builtins.readFile ./Dockerfile;
          };
      };
    };
}
