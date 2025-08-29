# immutable-os

Repository for template/test of immutable-os

## Convert OCI container image to Bootable OS image

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
