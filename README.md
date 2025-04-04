# Build Dockerfile/Containerfile with Nix

`buildContainerFile` is a Nix function to build an OCI container image from
your `Dockerfile` or `Containerfile` script. Build is performed in a super
lightweight VM with Nix sandbox relaxed to enable Internet access.


## Cowsay example

* Build container image from [Containerfile script](flake.nix)

```bash
  nix build -L --option sandbox relaxed --builders "" github:imincik/containerfile-nix#cowsay-example
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

## Sl example

* Build container image from [Dockerfile](Dockerfile)

```bash
  nix build -L --option sandbox relaxed --builders "" github:imincik/containerfile-nix#sl-example
```

* Run container with podman

```bash
  podman load -i ./result/sl.tar
  podman run -t localhost/sl:test

  Enjoy the train ...
```

## Usage

Check out [build-containerfile.nix](build-containerfile.nix) file.
