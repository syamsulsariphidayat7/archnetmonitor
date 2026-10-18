# AGENTS.md

Guidelines for AI agents (and humans) working on this repository. Read this
before making changes. For the current phase/status, see `PROGRESS.md`.

## Project overview

Custom [Quickshell](https://quickshell.outfoxxed.me/) shell configuration for
Hyprland, forked from [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland)
(Illogical Impulse + Waffle). The repo is the `~/.config/quickshell/ii` config
directory (symlinked via `install.sh`).

Deliberate deviations from upstream (both data-driven, defaults live in
`modules/common/Config.qml`):

- **NetSpeed** — live ↓/↑ network speed as an always-visible chip inside the
  bar's Resources group (styled like the RAM/swap/CPU chips), plus a Network
  column in the Resources popup and a Settings → Bar section. Reads
  `/proc/net/dev` for the default-route interface.
- **Idle** — `idle.inhibitByDefault` keeps the system awake on a fresh boot /
  new Hyprland instance, without toggling the quick toggle each time.

See the `NetSpeed internals` table below for the files that make up the widget.

## Tech stack

- **Quickshell** (Qt6/QML-based shell toolkit for Wayland)
- **QML / QtQuick** (QtQuick, QtQuick.Layouts, Quickshell.* modules)
- **Hyprland** as the target compositor (hyprland-qtutils, `hyprctl`, etc.)
- Bash/Python helper scripts under `scripts/`
- JSON translation files under `translations/`

## Architecture

Entry point is `shell.qml` (a `ShellRoot`). It loads common services and two
*lazy-loaded panel families*, switchable at runtime via
`Config.options.panelFamily` (`"ii"` or `"waffle"`).

| Path | Purpose |
| --- | --- |
| `shell.qml` | Shell root: services bootstrap, panel family loaders, global shortcuts |
| `GlobalStates.qml` | Singleton UI state (bar open, overlays, lock, etc.) |
| `modules/common/` | Shared singletons: `Config`, `Appearance`, `Directories`, `Icons`, `Images`, `Persistent` |
| `modules/ii/` | The "ii" panel family: `bar/`, `background/`, `sidebarLeft/`, `sidebarRight/`, `overlay/`, `overview/`, `lock/`, etc. |
| `modules/waffle/` | The "waffle" panel family: `looks/`, `startMenu/`, `taskView/`, `notificationCenter/`, etc. |
| `modules/settings/` | Settings UI pages (`settings.qml` hosts them) |
| `services/` | Singleton services (Network, Notifications, Audio, Battery, Weather, Ai, NetSpeed, …) |
| `panelFamilies/` | `PanelLoader.qml` + the family root components (`IllogicalImpulseFamily.qml`, `WaffleFamily.qml`) |
| `scripts/` | Helper scripts (wallpaper, colors, translations, …) |
| `translations/` | UI strings, one JSON file per locale; `en_US.json` is the source |
| `defaults/` | Default values/files (e.g. `defaults/ai/`) |

### NetSpeed internals

`ii`-only (see Decisions in `PROGRESS.md`). The requirement is that speed stays
visible *without hovering*, which is why the old standalone
`modules/ii/bar/NetSpeed.qml` widget was deleted.

| Path | Role |
| --- | --- |
| `services/NetSpeed.qml` | Singleton: polls `/proc/net/dev`, detects the default-route interface via `ip route`, exposes `downloadText`/`uploadText` (+ `*Compact`) and `formatSpeed()` |
| `modules/ii/bar/NetSpeedResource.qml` | The bar chip: colored ↓/↑ arrows + numbers in TextMetrics-reserved, `clip: true` slots so the bar never reflows; click launches `bar.netSpeed.monitor` in a terminal |
| `modules/ii/bar/Resources.qml` | Hosts the chip (first in the Resources group) |
| `modules/ii/bar/ResourcesPopup.qml` | Network column (↓/↑ full labels) in the hover popup |
| `modules/settings/BarConfig.qml` | Settings → Bar → "Net speed" section |
| `modules/common/Config.qml` | `bar.netSpeed.*` option tree (`enable`, `updateInterval`, `bits`, `compact`, `downloadColor`, `uploadColor`, `monitor`) |
| `services/Idle.qml` + `modules/settings/GeneralConfig.qml` | `idle.inhibitByDefault` — seeds the inhibitor on a new instance, restores persisted state on a same-instance reload |

## Conventions

- **QML formatting** is enforced by `.qmlformat.ini`: 4-space indent, no tabs,
  max column width 110, objects spacing. Run `qmlformat --verify <file>` (or
  `qmlformat -i <file>`) on anything you touch.
- **File naming:** components are PascalCase (e.g. `NetSpeedResource.qml`); the root
  object of every file is `id: root`.
- **Pragmas:** singletons and stateful components use
  `pragma Singleton` / `pragma ComponentBehavior: Bound` where appropriate —
  match the surrounding files.
- **Imports:** project modules first (`import qs.modules.common`,
  `import qs.services`), then Qt (`QtQuick`, `QtQuick.Layouts`), then Quickshell
  (`Quickshell`, `Quickshell.Io`, …) — match the style of the file being edited.
- **Config is data-driven:** all options live in `modules/common/Config.qml`
  under `JsonObject` properties and are read as `Config.options.<path>`. Never
  hardcode a user-tunable value in a widget. Settings pages edit the same tree.
- **Config persistence:** the live values live in
  `Directories.shellConfigPath` (`~/.config/illogical-impulse/config.json`).
  The `JsonAdapter` does **not** apply QML-declared defaults for keys that are
  absent from that JSON file, so a newly added option must be written into the
  live file (the Settings UI does it once the user touches the control).
- **Theming:** use `Appearance.colors.*` / `Appearance.font.*` /
  `Appearance.sizes.*`; never hardcode colors or font sizes.
- **i18n:** user-visible strings must go through the translations system
  (source key in `translations/en_US.json`). See `translations/tools/README.md`.
  Do **not** run `translations/tools/manage-translations.sh sync` blindly — it
  rewrites every locale file and drops keys that are missing from `en_US.json`.
  Add the key to `en_US.json` and mirror it into each locale by hand; other
  locales fall back to the English key via `Translation.tr()`.
- **Widgets are per-family:** shared behavior belongs in `modules/common/`;
  family-specific UI belongs under `modules/<family>/`. Reuse existing
  components (`StyledText`, `MaterialSymbol`, `W*` widgets) instead of
  reinventing them.

## Development workflow

```bash
./install.sh                       # symlink repo → ~/.config/quickshell/ii
qs -p ~/.config/quickshell/ii/shell.qml   # run (inside a Hyprland session)
```

Quickshell hot-reloads on file edits, so iterate by editing files in place.
The repo is versioned with git — keep commits small and focused.

## Validation

- No automated test suite exists. Validation = `qmlformat --verify` on changed
  files, plus a live load in Quickshell inside Hyprland.
- Check scripts with `bash -n` / `shellcheck` and Python with
  `python3 -m py_compile` when you touch `scripts/`.
- Keep the working tree clean between features; update `PROGRESS.md` when a
  phase/milestone completes.
