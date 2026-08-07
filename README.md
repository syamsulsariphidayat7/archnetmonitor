# archnetmonitor

Custom [Quickshell](https://quickshell.outfoxxed.me/) shell config for Hyprland,
based on [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) (Illogical
Impulse) with a **network speed (↓/↑) indicator** added to the bar.

This is the `~/.config/quickshell/ii` config directory.

## Features on top of upstream

- **NetSpeed indicator** — live download/upload speed shown as a **compact
  chip in the bar's Resources widget** (next to the RAM/swap/CPU chips), plus
  a Network detail column in the Resources hover popup. Data is polled from
  `/proc/net/dev` by the `services/NetSpeed.qml` singleton, auto-detecting
  the default-route interface.
- Config options (`Config.options.bar.netSpeed`): `enable`, `updateInterval`,
  `bits` (display in bits/s instead of bytes/s),  `compact` (short labels
  like `1.2M` on the bar chip), `downloadColor` / `uploadColor` (arrow colors
  on the chip), and `monitor` (network monitor opened in a terminal when the
  chip is clicked, e.g. `btop`).

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
