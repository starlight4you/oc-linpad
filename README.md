# oc-linpad

opencode-cli built and verified for the LinPad customized iSH ARM64 Alpine
environment.

## Quick install (inside a fresh LinPad iSH ARM64 Alpine)

```sh
curl -fsSL https://github.com/starlight4you/oc-linpad/releases/latest/download/install.sh | sh
```

Or with a local checkout:

```sh
./install.sh
```

Build a fakefs image instead:

```sh
./install.sh --rootfs /path/to/fs
```

## What's included in releases

- `opencode` — prebuilt `opencode-linux-arm64-musl` 1.2.10 binary
- `opencode-cache.tgz` — populated `/root/.cache/opencode` plugin cache
- `alpine-arm64-opencode-rootfs.tar.gz` — ready-to-use Alpine 3.21 rootfs
- `fakefsify` / `ish` — helper binaries

## iSH source patches

See `patches/` for the changes required in the LinPad iSH source tree:

- `epoll.c` — idempotent `EPOLL_CTL_ADD`
- `path.c` — NULL `at` handling in `path_normalize`
- `staticdefine.sh` — quoted include path
- `meson.build.vdso-arm64` — cross-compiler lookup
