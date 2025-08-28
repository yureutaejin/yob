# immutable-os

Repository for template/test of immutable-os

## Convert OCI container image to Bootable OS image

Please refer to https://github.com/osbuild/bootc-image-builder

```bash
mkdir -p ./output
sudo podman run \
    --rm -it \
    --privileged \
    --pull=newer \
    --security-opt label=type:unconfined_t \
    -v ./output:/output \
    -v ./config.toml:/config.toml:ro \
    -v /var/lib/containers/storage:/var/lib/containers/storage \
    quay.io/centos-bootc/bootc-image-builder:latest \
    --type qcow2 \
    --use-librepo=True \
    --rootfs btrfs \    # for OS like fedora distros which does not have root filesystem
    {target_image:tag}
```

## Wiki

- OCI Registry for OS based on bootc
  - quay.io/yuntae/immutable-os-bootc
- Memo for packages
  - container-management : (podman, buildah, skopeo)

## Appendix

- `podman login -u='{username}' -p='{credential}' {registry type}` saved credentials in `/run/user/{UID}/containers/auth.json`
  - https://stackoverflow.com/questions/77412593/how-are-docker-credentials-saved-in-podman
