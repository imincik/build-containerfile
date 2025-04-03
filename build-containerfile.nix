{ pkgs
  # Resulting image name
, name ? "image"
  # Resulting image tag
, tag ? "latest"
  # Dockerfile/Container file content
, script ? ""
  # Build context
, buildContext ? ""
  # List of extra arguments passed to image build command
  # Example: [ "--build-arg VAR='xyz'" ]
, extraArgs ? []
  # Amount of memory assigned to VM
, vmMemorySize ? 2048
}:

let
  registriesConf = pkgs.writeText "registries.conf" ''
    [registries.search]
    registries = ['docker.io', 'quay.io']
  '';
  containerFile = pkgs.writeText "Containerfile" script;

in
pkgs.vmTools.runInLinuxVM (
  pkgs.runCommand "build-container-file"
  {
    memSize = vmMemorySize;
    # QEMU_OPTS = "-nic user,model=virtio-net-pci";
    QEMU_OPTS = "-netdev user,id=net0 -device virtio-net-pci,netdev=net0";

    nativeBuildInputs = with pkgs; [
      dhcpcd
      iproute2
      kmod
      podman
      util-linux
    ];

    __noChroot = true;
  } ''
    mount -t cgroup2 cgroup /sys/fs/cgroup

    modprobe virtio_net
    ip link set eth0 up

    mkdir -p /var/lib/dhcpcd
    touch /etc/dhcpcd.conf
    dhcpcd eth0

    export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt

    install -Dm555 ${pkgs.skopeo.src}/default-policy.json ~/.config/containers/policy.json
    install -Dm555 ${registriesConf} ~/.config/containers/registries.conf

    mkdir $out
    podman build --tag ${name}:${tag} --file ${containerFile} ${builtins.concatStringsSep " " extraArgs} ${buildContext}
    podman save localhost/${name}:${tag} --format docker-archive --output $out/${name}.tar
  ''
)
