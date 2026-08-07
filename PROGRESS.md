# PROGRESS.md

Phase tracker for this repo. Update after each milestone. Current phase:
**Development**.

Last updated: 2026-08-07

## Phase tracker

| Phase | Status | Notes |
| --- | --- | --- |
| 1. Discovery | ✅ Done | Repo initialized; forked end-4/dots-hyprland; README written |
| 2. Design | ✅ Done | Config-driven options (`Config.qml`); dual panel families (`ii`, `waffle`); NetSpeed designed as standalone bar widget |
| 3. Development | 🔄 In progress | See milestones below |
| 4. Testing & polish | ⏳ Not started | Live validation on Hyprland, edge cases |
| 5. Docs & release | ⏳ Not started | README polish, feature docs |

## Development milestones

### ✅ M1 — Initial config + NetSpeed widget (done, commit `0463d48`)

- Full ii/waffle config imported and runnable via `install.sh` → `~/.config/quickshell/ii`.
- **NetSpeed** bar widget (`modules/ii/bar/NetSpeed.qml`):
  - Reads `/proc/net/dev`, auto-detects default-route interface (`ip route`).
  - Shows ↓/↑ speed (auto B/s → KB/s → MB/s → GB/s formatting).
  - Config toggle added: `Config.options.bar.netSpeed.enable` (default on) and
    `updateInterval` (default 1000 ms).
  - Interface re-detection on network change (`Network.networkNameChanged`).

### ✅ M2 — NetSpeed relocated: bar chip + Resources popup (done)

User request evolved: the speed must be visible **without hovering**, combined
with the RAM/swap/CPU resources in the bar.

- New singleton service `services/NetSpeed.qml` (polling + formatting logic
  ported from the old bar widget; same pattern as `ResourceUsage`).
- New compact bar chip `modules/ii/bar/NetSpeedResource.qml` added to the
  Resources widget (`modules/ii/bar/Resources.qml`) — always visible, styled
  like the RAM/swap/CPU chips (`↓/↑` speeds).
- `modules/ii/bar/ResourcesPopup.qml` shows a **Network** detail column (↓/↑
  speeds) alongside RAM/Swap/CPU on hover.
- Removed the old `NetSpeed` widget from the right-sidebar button
  (`modules/ii/bar/BarContent.qml`); deleted `modules/ii/bar/NetSpeed.qml`.
- Added `Download:` / `Upload:` i18n keys (`translations/en_US.json`). Other
  locales fall back to the key (English) via `Translation.tr()` — do **not**
  run `manage-translations.sh sync` blindly: it rewrites locale files massively
  (deletes keys missing from en_US). Sync i18n keys manually if needed.
- Wrote `bar.netSpeed` explicitly into the live
  `~/.config/illogical-impulse/config.json` (`enable: true`,
  `updateInterval: 1000`) — the JsonAdapter does not apply QML-declared
  defaults for keys absent from the JSON file.
- **Format options** (`bar.netSpeed.bits` / `bar.netSpeed.compact`):
  `bits: true` shows speeds in bits/s (×8, `Mb/s` units); `compact: true`
  shortens the bar chip to `1.2M` / `300K` style. `formatSpeed` in
  `services/NetSpeed.qml` now exposes full + compact variants
  (`downloadText(Compact)` / `uploadText(Compact)`); the chip picks compact
  per config, the popup keeps the full label. Verified with node against
  bytes/bits × full/compact combinations.
- **Fixed chip width** (`modules/ii/bar/NetSpeedResource.qml`): each speed
  number lives in a TextMetrics-reserved slot (`150 MB/s` full / `150M`
  compact, `clip: true`) so the chip never resizes when the numbers change
  and the bar layout stays stable. Placeholder number is `150`; bump
  `reserveUnitText` if the link can exceed it.
- **Colored ↓/↑ arrows on the chip** (replaces the `network_check` logo):
  `arrow_downward` in `bar.netSpeed.downloadColor` (default blue `#42a5f5`)
  and `arrow_upward` in `bar.netSpeed.uploadColor` (default orange `#ffa726`),
  both theme-friendly and configurable in `config.json`.
- **Click-to-monitor**: clicking the chip launches
  `bar.netSpeed.monitor` (default `btop`) in a terminal via
  `Quickshell.execDetached` (pattern from `LauncherSearch.qml`); empty string
  disables the click. Verified: `kitty -1 -e btop` launches btop.

### ✅ Fixed pre-existing upstream warnings (done, 2026-08-07)

- `NotificationPopup.qml:17` — consumers read `notifications.forceMonitor`
  but Config defined `notifications.monitor`; renamed Config key +
  `config.json` to `forceMonitor` (settings UI label: "Force specific monitor").
- `BarContent.qml:134` — removed stale `padding: workspacesWidget.widgetPadding`
  (no such property on `Workspaces`; BarGroup default `padding: 5` applies).
- `ToolbarTabBar.qml:59` — guarded `contentItem.children[currentIndex]` with
  `?? root` (was undefined transiently during construction).
- Remaining log noise is benign: Qt `propertyCache.append` hints and the
  generated-translations-dir fallback.

### ✅ NetSpeed settings UI (done, 2026-08-07)

- New **Net speed** section in `modules/settings/BarConfig.qml` (Settings →
  Bar): Enable, Update interval (ms), Bits per second, Compact labels,
  Arrow colors (download/upload hex inputs), and Monitor (click action).
- All keys bound to `Config.options.bar.netSpeed.*`; i18n keys added to
  `translations/en_US.json`.
- Validated by launching the settings window (focused via `hyprctl
  activewindow`), cycling to the Bar page with `wtype` Ctrl+Tab, and
  confirming zero errors in the settings log.

### ✅ Deployed to live shell (done, 2026-08-07)

- Ran `./install.sh` — old `~/.config/quickshell/ii` backed up to
  `ii.bak.1786088006`, repo now symlinked.
- Restarted the shell (`killall qs; qs -c ii`, logs at `/tmp/qs-ii.log`).
- **Bug found & fixed during deploy:** `ifaceProc.text()` is not a function in
  Quickshell 0.2.1 — the old widget had the same latent bug (interface
  detection silently failed, fallback matched first non-`lo` iface). Fixed to
  use the `StdioCollector`'s own `text` property (pattern from `Network.qml`).
- Verified: clean boot, no NetSpeed errors.

### ⏳ M3 — Next steps (backlog, pick one)

Ideas, not commitments:

- **NetSpeed in the waffle family** — reuse the `NetSpeed` service to show
  speed in the waffle bar/popup for parity between panel families.
- **NetSpeed settings UI** — expose enable/interval (and future options) in the
  settings pages (`modules/settings/`).
- **Widget enhancements:**
  - Option to display **bits/s** (vs bytes/s) and control decimal places.
  - Hide/zero-out the popup rows when idle (no traffic).
  - Click action to open a monitor (`btop`, `nethogs`, `bmon`).
  - History sparkline in the popup (extend the Resources popup pattern).
- **i18n** — make any new user-visible strings translatable (see
  `translations/tools/README.md`).

### ⏳ M2 — Next steps (backlog, pick one)

Ideas, not commitments:

- **NetSpeed in the waffle family bar** — port the widget to the waffle bar for
  parity between panel families.
- **NetSpeed settings UI** — expose enable/interval (and future options) in the
  settings pages (`modules/settings/`).
- **Widget enhancements:**
  - Option to display **bits/s** (vs bytes/s) and control decimal places.
  - Hide/zero-out the widget when idle (no traffic).
  - Click action to open a monitor (`btop`, `nethogs`, `bmon`).
  - Popup with a short history sparkline/graph (reuse the `Resources` popup pattern).
- **i18n** — make any new user-visible strings translatable (see
  `translations/tools/README.md`).

## Open questions / risks

- NetSpeed is shown only in the `ii` family (via the Resources popup); the
  `waffle` family has no equivalent yet.
- `/proc/net/dev` counters wrap and reset on interface reconnects — the service
  already guards with `Math.max(0, …)`, but verify on wifi reconnect.
- Validation depends on a live Hyprland session (no CI).
