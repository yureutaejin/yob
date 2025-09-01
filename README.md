# Immutable OS - bootc

(Experimental) Repository for building immutable OS using [bootc](https://bootc-dev.github.io/)

## 1. Build OCI image with bootable container

![Bootable Container](https://developers.redhat.com/sites/default/files/styles/article_floated/public/image1_62.png.webp?itok=c0vYglLs)

As everybody knows, The Linux container usually shares kernel with host OS,  
so that we can easily create a "Container" which is more lightweight and faster than Virtual Machine.

The bootc project uses the method in reverse to create OS using the Linux container techniques.  
Unlike usual OCI containers, the base OCI container (so called, bootable container) that bootc uses have below things already.

- Linux kernel
- Bootloader
- systemd
- System utilities & drivers

So we can create OS image using OCI container techniques which is familiar to modern developers/engineers.

### How to build it

> [!NOTE]
> Containerfile is the format of Podman. But it is okay to build it with Docker. (OCI format)

1. Clone this repository
2. Edit [Containerfile](./Containerfile) as needed
   - Currently, OCI container from RHEL OS (especially, Atomic OS) provides bootable container.
     - Official RHEL Family : fedora-{bootc,Silverblue,CoreOS}, Almalinux-bootc, CentOS-bootc, RHEL for edge, RHEL CoreOS
     - Custom : Project Universal Blue, HeliumOS
   - `/usr` will be read-only. Put read-only data and executables in `/usr`
   - Put configuration files in `/usr` or `/etc`
   - Put "data" (log, databases, etc.) underneath `/var`
3. Build the OCI container image
   - `{docker,podman,etc} build -t {image_name}:{tag} .`
4. Use it like usual OCI containers.
   - ***e.g.*** `{docker,podman,etc} run -it {image_name}:{tag} /bin/bash`

## 2. Convert OCI image to bootable disk

> [!NOTE]
> Currently, bootc-image-builder is not stable yet.
>
> (It highly depends on podman runtime which is popular for rootless, even though it uses `privileged` and `sudo` to convert OCI to bootable images)

Please refer to https://github.com/osbuild/bootc-image-builder

```bash
mkdir -p ./output

# bootc-image-builder does not pull target image
sudo podman pull {source_image:tag}

# It sacrifices the benefit of rootless Container Runtime
# if you add package repository yourself(not based on $pkgsystem), `iso` option makes problems sometimes
sudo podman run \
    --rm -it \
    --privileged \
    --pull=newer \
    --security-opt label=type:unconfined_t \
    -v ./output:/output \
    -v ./config.toml:/config.toml:ro \
    -v /var/lib/containers/storage:/var/lib/containers/storage \
    quay.io/centos-bootc/bootc-image-builder:latest \
    --type {iso,qcow2} \
    --use-librepo=True \
    --rootfs {ext4,btrfs,xfs} \
    {target_image:tag}
```

## Wiki

- OCI Registry for OS based on bootc
  - quay.io/yuntae/immutable-os-bootc
- Memo for packages
  - container-management : (podman, buildah, skopeo)

### Related Issues

- [systemd-remount-fs.service failed to start](https://discussion.fedoraproject.org/t/systemd-remount-fs-service-failed-to-start/148619)

## Appendix

- `podman login -u='{username}' -p='{credential}' {registry type}` saved credentials in `/run/user/{UID}/containers/auth.json`
  - https://stackoverflow.com/questions/77412593/how-are-docker-credentials-saved-in-podman
