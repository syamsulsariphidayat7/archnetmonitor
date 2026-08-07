# AGENTS.md

Guidelines for AI agents (and humans) working on this repository. Read this
before making changes. For the current phase/status, see `PROGRESS.md`.

## Project overview

Custom [Quickshell](https://quickshell.outfoxxed.me/) shell configuration for
Hyprland, forked from [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland)
(Illogical Impulse + Waffle). The repo is the `~/.config/quickshell/ii` config
directory (symlinked via `install.sh`).

The project's unique feature so far is the **NetSpeed** bar widget
(`modules/ii/bar/NetSpeed.qml`) — a live ↓/↑ network speed indicator reading
`/proc/net/dev`, with a config toggle.

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
| `services/` | Singleton services (Network, Notifications, Audio, Battery, Weather, Ai, …) |
| `panelFamilies/` | `PanelLoader.qml` + the family root components (`IllogicalImpulseFamily.qml`, `WaffleFamily.qml`) |
| `scripts/` | Helper scripts (wallpaper, colors, translations, …) |
| `translations/` | UI strings, one JSON file per locale; `en_US.json` is the source |
| `defaults/` | Default values/files (e.g. `defaults/ai/`) |

## Conventions

- **QML formatting** is enforced by `.qmlformat.ini`: 4-space indent, no tabs,
  max column width 110, objects spacing. Run `qmlformat --verify <file>` (or
  `qmlformat -i <file>`) on anything you touch.
- **File naming:** components are PascalCase (e.g. `NetSpeed.qml`); the root
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
- **Theming:** use `Appearance.colors.*` / `Appearance.font.*` /
  `Appearance.sizes.*`; never hardcode colors or font sizes.
- **i18n:** user-visible strings must go through the translations system
  (source key in `translations/en_US.json`). See `translations/tools/README.md`.
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
