# archnetmonitor

Custom [Quickshell](https://quickshell.outfoxxed.me/) shell config for Hyprland,
based on [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) (Illogical
Impulse) with a **network speed (↓/↑) indicator** added to the bar.

This is the `~/.config/quickshell/ii` config directory.

## Features on top of upstream

- **NetSpeed bar widget** (`modules/ii/bar/NetSpeed.qml`) — live download/upload
  speed next to the wifi icon, reading `/proc/net/dev` and auto-detecting the
  default-route interface.
- Config toggle: `Config.options.bar.netSpeed.enable` / `updateInterval`.

## Prerequisites

- **Hyprland** (Wayland compositor)
- **quickshell** — the Illogical Impulse pinned build:
  AUR package `illogical-impulse-quickshell-git` (or upstream `quickshell-git`)
- Runtime CLIs used by the shell: `networkmanager` (`nmcli`), `brightnessctl`,
  `bluez`/`bluez-utils` (`bluetoothctl`), `iproute2` (`ip`), `bash`, `awk`
- Qt6 dependencies pulled in by the quickshell package (see its PKGBUILD)

> The easiest way to get all dependencies is to install the base of
> [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) first, then
> overlay this config.

## Install

```bash
git clone git@github.com:syamsulsariphidayat7/archnetmonitor.git
cd archnetmonitor
./install.sh
```

`install.sh` symlinks this repo to `~/.config/quickshell/ii` (backing up any
existing directory to `ii.bak.<timestamp>`).

## Run

Launched by Hyprland autostart, e.g.:

```bash
qs -p ~/.config/quickshell/ii/shell.qml
```

or reload a running instance by editing any file (Quickshell auto-reloads).

## License

Inherits the upstream license (see end-4/dots-hyprland).
