{ pkgs

  # Resulting image name.
, name ? "image"

  # Resulting image tag.
, tag ? "latest"

  # Dockerfile/Container file content.
  # Example:
  # FROM debian:12-slim
  # RUN apt-get update && apt-get install -y cowsay
, script ? ""

  # Build context.
, buildContext ? ""

  # List of extra arguments passed to image build command.
  # Example: [ "--build-arg VAR='xyz'" ]
, extraArgs ? [ ]

  # Memory size in MB assigned to VM.
  # Half of the memory is alocated to tmpfs mounts.
, vmMemorySize ? 2048

  # Size of disk in MB mounted to /var/lib in VM.
  # If vmDiskSize = 0, no disk is mounted.
, vmDiskSize ? 4096
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

    preVM =
      if vmDiskSize > 0 then
        pkgs.vmTools.createEmptyImage
          {
            size = vmDiskSize;
            fullName = "var-lib-image";
            destination = "./var-lib-image";
          }
      else false;

    nativeBuildInputs = with pkgs; [
      dhcpcd
      e2fsprogs
      iproute2
      kmod
      podman
      util-linux
    ];

    __noChroot = true;
  } ''
    if [ "${toString vmDiskSize}" != "0" ]; then
      echo "Mounting disk image to /var/lib ..."
      mkdir /var/lib
      mkfs.ext4 /dev/${pkgs.vmTools.hd}
      mount /dev/${pkgs.vmTools.hd} /var/lib
    fi

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

    echo "Free space on /var/lib disk ..."
    df -h /var/lib
  ''
)
