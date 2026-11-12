# Packaging (AUR)

Sylphrena is four packages. All are `-git` packages: their version follows the repository.

| Package | Repository | What it is |
| --- | --- | --- |
| `sylphrena-cli-git` | [sylphrena-cli](https://github.com/iMacnucintosh/sylphrena-cli) | the `sylph` command |
| `seeker-git` | [seeker](https://github.com/iMacnucintosh/seeker) | the file manager (`seeker`) |
| `things-git` | [things](https://github.com/iMacnucintosh/things) | the package manager and extension manager |
| `sylphrena-shell-git` | this repository | the shell; depends on the three above |

Each has its `PKGBUILD` and `.SRCINFO` in its repository's `packaging/` folder.

## Build and install from a clone

```bash
cd packaging && makepkg -si      # in each repository, the three apps first and the shell last
```

## Publish in the AUR (needs an AUR account and your SSH key)

```bash
pkg=things-git                    # then seeker-git, sylphrena-cli-git, sylphrena-shell-git
git clone ssh://aur@aur.archlinux.org/$pkg.git /tmp/aur-$pkg
cp PKGBUILD .SRCINFO /tmp/aur-$pkg/        # from the repository's packaging/ folder
cd /tmp/aur-$pkg && git add PKGBUILD .SRCINFO && git commit -m "Update" && git push
```

After changing a `PKGBUILD`: `makepkg --printsrcinfo > .SRCINFO`.

Notes:
- `seeker` (without `-git`) already exists in the AUR and is another program, so ours is `seeker-git` and conflicts with it.
- Dependencies that only exist in the AUR (an AUR helper such as `yay` installs them): `quickshell-git`, `qt6-m3shapes-git`
  (shell), `python-materialyoucolor` (CLI) and the optional `ttf-rubik-vf` (clock and workspace font).
- The shell's version comes from the nearest `v0.*` tag (the project this forked has `v1.*` and `v2.*`).
- The wallpaper that ships with the shell has its own licence: see `assets/wallpapers/README.md`.
