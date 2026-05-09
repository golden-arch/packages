# golden-arch/packages

PKGBUILDs for the 5 Golden Arch brand packages.

## Packages

| Package | Purpose |
|---|---|
| `golden-arch-keyring` | GPG public key + trust file for our pacman repo |
| `golden-arch-theme` | KDE + Hyprland + GTK/Qt Everforest theme, Papirus icon recolor |
| `golden-arch-defaults` | sysctl hardening, AppArmor profiles, `/etc/skel/` dotfiles |
| `golden-arch-branding` | Wallpapers, Plymouth, GRUB, SDDM themes, Calamares slideshow |
| `golden-arch-hyprland-config` | Standalone Hyprland config (separate from -theme for KDE-only users) |

## Building

```bash
cd golden-arch-keyring
makepkg -si
```

Sign before publishing:
```bash
gpg --detach-sign --no-armor golden-arch-keyring-*.pkg.tar.zst
```

## Publishing

Built packages go into `golden-arch/repo` and are indexed with `repo-add`.
