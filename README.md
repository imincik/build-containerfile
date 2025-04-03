# Build Dockerfile/Containerfile with Nix

`buildContainerFile` is a Nix function to build an OCI container image from
your `Dockerfile` or `Containerfile` script. Build is performed in a super
lightweight VM with Nix sandbox relaxed to enable Internet access.


## Cowsay example

* Build container image

```bash
  nix build --option sandbox relaxed --builders "" github:imincik/containerfile-nix#cowsay-example
```

* Run container with podman

```bash
  podman load -i ./result/cowsay.tar
  podman run localhost/cowsay:test /usr/games/cowthink "It works !"
   ____________
  ( It works ! )
   ------------
          o   ^__^
           o  (oo)\_______
              (__)\       )\/\
                  ||----w |
                  ||     ||
```

## Usage

Check out [flake.nix](flake.nix) file.
