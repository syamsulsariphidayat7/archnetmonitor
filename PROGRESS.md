# PROGRESS.md

Phase tracker for this repo. Update after each milestone. Current phase:
**Development**.

Last updated: 2026-10-19

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
  and `arrow_upward` in `bar.netSpeed.uploadColor` (default green `#7D9C65`
  since M4), both theme-friendly and configurable in `config.json`.
- **Click-to-monitor**: clicking the chip launches
  `bar.netSpeed.monitor` (default `btop`) in a terminal via
  `Quickshell.execDetached` (pattern from `LauncherSearch.qml`); empty string
  disables the click. Verified: `kitty -1 -e btop` launches btop.

### ✅ M3 — "Keep awake on boot" idle option (done, 2026-10-17)

- New config option `Config.options.idle.inhibitByDefault` (default `false`):
  when enabled, the idle inhibitor is turned on automatically on a **new**
  Hyprland instance (fresh boot / compositor restart), so the system stays
  awake without toggling the quick toggle each time.
- `services/Idle.qml`: on `Persistent.ready`, a **new** instance now seeds
  `root.inhibit` from the config default (previously the persisted state was
  reused verbatim); the same-instance path still restores
  `Persistent.states.idle.inhibit`. Added a `Persistent.ready` guard to the
  first `Connections` block, plus a second `Connections` on `Config.ready` so
  the default is re-applied when `Config` finishes loading *after* `Persistent`
  (avoids seeding `false` because the option tree wasn't ready yet).
- Settings UI: new **Idle** section in `modules/settings/GeneralConfig.qml`
  (icon `coffee`) with a single "Keep awake on boot" `ConfigSwitch`.
- i18n keys added to `translations/en_US.json` ("Idle", "Keep awake on boot",
  the tooltip). Other locales fall back to the English key — do **not** run
  `manage-translations.sh sync` blindly (see M2 note).
- Wrote `idle.inhibitByDefault: true` into the live
  `~/.config/illogical-impulse/config.json`; validated a clean boot in the
  running shell (no Idle/Config errors in the Quickshell log).

### ✅ Docs — AGENTS.md refreshed to match the shipped code (done, 2026-10-19)

- The project overview still described the feature as the deleted
  `modules/ii/bar/NetSpeed.qml` bar widget. Replaced it with the current
  deviations from upstream (NetSpeed chip + `idle.inhibitByDefault`) and the
  real file paths.
- Added a **NetSpeed internals** table (service, chip, Resources host, popup,
  settings page, Config keys) so a fresh session doesn't re-derive the layout.
- New convention bullets: config persistence (JsonAdapter ignores QML defaults
  for keys absent from the live `config.json`) and the i18n warning not to run
  `manage-translations.sh sync` blindly (also recorded in M2 above).
- Docs-only change — no QML touched, no shell reload needed.

### ✅ M4 — NetSpeed hardening + pembersihan docs/i18n (done, 2026-10-19)

Hasil audit setelah M3. Empat commit: `884ae28`, `d7adffe`, `63bddb1`, `f2ee968`.

- **Bug: deteksi interface lewat posisi kolom.** `ip route | awk '{print $5}'`
  salah untuk rute default tanpa gateway (VPN/tunnel, mis.
  `default dev wg0 scope link` → kolom 5 = `scope`), sehingga chip macet di
  `--` permanen karena regex `/proc/net/dev` tak pernah match. Sekarang awk
  mencari token `dev`. Diuji: rute normal → `enp0s20f0u7`, sintetis wg0 → `wg0`.
- **Bug: gate sampel pertama.** `lastRxBytes > 0 && lastTxBytes > 0` menahan
  pembaruan teks kalau satu arah masih nol (baru boot, mesin hanya download).
  Diganti flag `hasSample`. Sampel juga direset saat interface berganti agar
  delta lintas interface tidak dihitung.
- **Bug: interface tidak pernah di-refresh.** Rute default bisa berpindah tanpa
  `Network.networkName` berubah. Ditambah deteksi ulang tiap 30 s
  (`ifaceTimer`) + guard `ifaceProc.running` (dulu `exec()` bisa dipanggil saat
  proses masih jalan). Kalau rute default hilang dan interface lama sudah tidak
  ada di `/proc/net/dev`, `netIface` direset agar deteksi otomatis aktif lagi.
- **Default `bar.netSpeed` diselaraskan dengan config live:** `bits` `false` →
  `true` (bit/s), `uploadColor` `#ffa726` → `#7D9C65`. Placeholder warna di
  Settings → Bar ikut disesuaikan (key i18n lama tidak dipakai locale lain).
- **Docs:** komentar kepala `services/Idle.qml` (masih "wrapper date and time
  strings") dan `services/NetSpeed.qml` (klaim "bar stays identical to upstream")
  diperbaiki; README mendokumentasikan deviasi `idle.inhibitByDefault` + default
  `bits` baru + ketergantungan terminal/monitor; AGENTS.md mengganti resep
  `qmlformat --verify` (tidak ada di qmlformat 6.12, biner di
  `/usr/lib/qt6/bin/`) dengan resep diff dan larangan `qmlformat -i`.
- **i18n:** `"Network"` ditambahkan ke `en_US.json` (satu-satunya key yang hilang
  di sumber); header Network di `ResourcesPopup.qml` dibungkus `Translation.tr()`;
  15 key seksi NetSpeed + Idle diterjemahkan tangan ke `id_ID.json`. Locale lain
  tetap fallback ke Inggris.
- Belum divalidasi live: perlu reload Quickshell di Hyprland (atau boot baru)
  untuk memastikan chip tetap normal dan `--` hanya muncul sesaat di awal.

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

## Decisions

- **2026-10-08: NetSpeed stays `ii`-only.** Porting it to the `waffle` panel
  family was considered and deliberately rejected by the repo owner (the
  waffle family is not used). Backlog items referencing waffle were removed
  so this file stays honest about the project's direction.

## Backlog (ideas, not commitments)

- **Widget enhancements:**
  - Option to control decimal places in the speed formatting.
  - Hide/zero-out the popup rows when idle (no traffic).
  - History sparkline in the popup (extend the Resources popup pattern).
- **i18n** — make any new user-visible strings translatable (see
  `translations/tools/README.md`).

## Open questions / risks

- `/proc/net/dev` counters wrap and reset on interface reconnects — the service
  guards with `Math.max(0, …)` and re-detects the interface every 30 s (M4),
  but verify on wifi reconnect / VPN toggle.
- Interface detection depends on `ip route show default`; if the default route
  is only present in a non-main table (policy routing), detection falls back to
  the first non-`lo` interface in `/proc/net/dev`.
- Validation depends on a live Hyprland session (no CI); `qmlformat` only
  serves as a style diff, there is no syntax test.
