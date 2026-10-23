# AGENTS.md

Terminal Protocol Controller: an Omarchy shell plugin (`anerti.terminal-protocol-controller`) that puts a radiation icon in
the bar. Its popup has one switch per part of the
[Dark Terminal Protocol](https://github.com/Anerti/omarchy-dark-terminal-protocol-theme) theme:
menu bar, menu, mouse cursor, CRT effect, unlock (lock) screen, login (boot) screen. If the theme
is missing, the plugin clones it into `~/.config/omarchy/themes/dark-terminal-protocol`.

It also ships everything of the theme's beyond its colour files: the shell plugins
(`plugins/`), the VaultTec cursors, the CRT screen shader and the Plymouth boot screen. So the
Terminal Protocol themes (`dark-terminal-protocol` and its coloured variant
`colored-terminal-protocol`) share one copy instead of each carrying its own. Each theme
keeps its colours, wallpapers and logo.

## Layout

| Path | What it is |
| ---- | ---------- |
| `manifest.json` | Plugin manifest: one `bar-widget`, entry point `Panel.qml`, `defaultSection: right`. |
| `Panel.qml` | Bar button and popup. It shows `bin/terminal-protocol-controller status` and starts `bin/terminal-protocol-controller set`, and does no work itself. |
| `RadiationIcon.qml` | The bar and hero icon: `assets/radiation.png` (the Wikimedia radiation warning symbol as a white mask) tinted like the glyph icons. |
| `PanelArt.qml`, `assets/` | The tinted GIF under the popup's hero, the same `PanelArt.qml` as the panels in `plugins/`. |
| `plugins/anerti.*` | The theme's Omarchy shell plugins, each a clone of a built-in (`manifest.json` → `omarchy.clonedFrom`). `plugins/omarchy-version` records the Omarchy release they were last synced with (`tools/upstream-check`). Omarchy only scans the top level of `~/.config/omarchy/plugins`, so these nested copies are never loaded from here. |
| `bin/vault-tec-plugins` | `install` copies plugins from `plugins/` into `~/.config/omarchy/plugins/<id>` (rsync) and restarts the shell when one changed; a plugin is enabled only on its first install. `sync` copies missing ones (left off) and updates the rest, skipping a copy edited in place; it restarts the shell only when an enabled plugin changed, and otherwise rescans. `enable`, `disable`, `place-bar` and `restart` are the switches' steps. |
| `cursors/VaultTec` | Built XCursor theme (generated: `tools/build-cursors`, from the SVGs inside it; `rsvg-convert`, `magick`). |
| `hooks/vault-tec-cursor` | Omarchy `theme-set` / `post-boot` hook: VaultTec cursors while a `*terminal-protocol*` theme is active, the previous cursor back otherwise. |
| `bin/vault-tec-cursor` | `install` copies the cursors to `~/.local/share/icons/VaultTec` and the hook into `~/.config/omarchy/hooks/{theme-set,post-boot}.d/`; `uninstall` puts the previous cursor back and removes both. |
| `assets/crt.frag` | The CRT screen shader: dark scanlines every 4 px and a vignette, the same under every theme. |
| `bin/vault-tec-crt` | CRT screen shader toggle: `on\|off\|toggle\|status`. |
| `previews/` | Screenshots of the menu, a panel and the lock screen, for the READMEs (the boot screen's are generated in `plymouth/`). |
| `plymouth/src/` | Boot screen sources: `boot.html` + `fallout.css` (mockup copies), `vault-tec.script` template, `render-footer`, the Vault Boy GIF, the font and a copy of the theme's logo. |
| `plymouth/vault-tec/` | Built Plymouth theme (generated, ~4 MB of PNG sprites). |
| `bin/vault-tec-plymouth` | Boot screen `install\|uninstall\|test` (sudo). |
| `tools/` | `build-plymouth`, `build-cursors`, `clone-panel` (new panel from a built-in), `upstream-check` (what changed in the built-ins the clones came from), `build-standby` (the lock's PLEASE STAND BY card). |
| `bin/terminal-protocol-controller` | Backend: `status` (JSON), `install` (clone the theme, sync the plugins), `set <part> <on\|off>`. |
| `tests/dry-run` | Runs every switch against a stub theme and stub `omarchy`/`gsettings`/`plymouth` commands, and checks which steps run. |

## How it works

- **Plugin steps.** The `bar`, `menu` and `unlock` switches run `bin/vault-tec-plugins`
  (`install` + `enable` for on, `disable` for off, which also re-enables the built-in each
  clone replaces), then `place-bar` and `restart`. Output goes to
  `~/.cache/terminal-protocol-controller/control.log`. They were the theme's old
  `full-theme.sh` steps (`git show f60a4ea:full-theme.sh` in the theme).
- **The rest:** `cursor`, `crt` and `login` run `bin/vault-tec-cursor`, `bin/vault-tec-crt`
  and `bin/vault-tec-plymouth`.
- **Installed** means the theme's `colors.toml` exists and every plugin in `plugins/` is in
  `~/.config/omarchy/plugins`. `install` clones the theme if needed (into `<dir>.part`,
  moved into place when complete; a broken folder already there is moved to
  `<dir>.broken-<time>`), then runs `vault-tec-plugins sync`:
  - missing plugins are copied and left off (a user plugin is off until `shell.json`
    names it), so a fresh install never changes the desktop;
  - installed ones are updated, and the shell restarts if an enabled one changed, since
    it keeps the QML it loaded; otherwise a rescan, which `omarchy plugin enable` needs;
  - a copy with a file newer than this checkout's newest one for that plugin is kept: it
    was edited in place (rsync copies mtimes, so a synced copy is never newer). Copy such
    edits back into `plugins/` before relying on the sync.
- **Parts:**
  - `bar`: every plugin in `plugins/` except `anerti.menu` and `anerti.lock`. The list is
    computed from the folder.
  - `menu`: `anerti.menu`.
  - `unlock`: `anerti.lock`.
  - `login`: the Plymouth boot screen, `bin/vault-tec-plymouth`.
  - `cursor`: VaultTec cursors and their hooks installed (not the cursor in use: the hook
    shows them only under a Terminal Protocol theme).
  - `crt`: `bin/vault-tec-crt`, which writes or removes
    `~/.local/state/omarchy/toggles/hypr/vault-tec-crt.lua` (loaded by Omarchy on every
    Hyprland reload) pointing `screen_shader` at `assets/crt.frag` in the checkout that wrote
    it, if that file still exists.
- **The bar layout follows the bar and menu.** After switching `bar` or `menu`, `place_bar`
  reads the new status and lays the bar out for it. Enabling or disabling a clone only swaps
  its id where it sits in `shell.json`, and re-enabling `omarchy.menu` (menu *and* logo
  button) drops it in the centre, so `place_bar` sets the layout itself (the right side is
  never touched):
  - Vault-Tec: the wedge alone in the centre, anchored there; every other widget on the left.
  - Built-in: `omarchy.menu` then `omarchy.workspaces` alone on the left; every other
    widget in the centre, anchored on the clock.
  Widgets move between the two with their settings, so switching back and forth is lossless.
  Plugin switches end with `restart`. `crt`, `cursor` and `login` do not restart the shell.
- **Detached, serialised.** A shell restart kills the shell's child processes, so `Panel.qml`
  starts `set` with `setsid -f`. The backend holds `~/.cache/terminal-protocol-controller/control.lock` while
  a switch or an `install` runs (each monitor's panel runs `install` at load). `status` reports that as `busy`.
- **Optimistic switches.** While a change is in flight, `Panel.qml` keeps the wanted value in
  `pending`. It drops that value once the status matches, or once the backend is idle and
  3 s have passed. The 3 s cover a poll that lands before the backend takes its lock.
- **Login needs sudo.** It opens `omarchy-launch-floating-terminal-with-presentation`, where
  the user types their password. The initramfs is then rebuilt. The launcher returns at
  once, so the terminal runs `vault-tec-plymouth` under `flock login.lock`, and the backend
  waits (up to 30 s) for it to take that lock and then for it to let go, staying `busy`.
- **Install at load.** Every panel runs `install` at load, detached like `set` (a plugin
  update can restart the shell), and reads the result from `status`: done once the backend
  is idle and 3 s have passed. If `installed` is still false, it tries again only the next
  time the popup opens.
- `TERMINAL_PROTOCOL_THEME_DIR` overrides the theme location. The test uses it.

## Plugins

- `anerti.menu`: Pip-Boy menu (replaces `omarchy.menu`). `Menu.qml` is the built-in's with no
  comments, plus (keep these when syncing it with a new release):
  - above the card, the Vault-Tec logo (20 px tall, as in the bar's wedge) and the Vault Boy GIF
    of the highlighted row's section (`artSections`; `artZooms` enlarges `remove`), spaced
    evenly with the search line by `brandGap`. Prompts (`select`/`input`) keep the bare card;
  - a centred search line with a blinking block cursor, and no label on the root menu;
  - the card 380 wide instead of 300;
  - the section path of the highlighted search result in the selected text colour;
  - `RollWipe` in its own full-screen, click-through window, played when the menu shows or
    hides, unless a roll is still running;
  - a private app library for when the shell hands it none.
- `anerti.lock`: Omarchy terminal lock screen (`authentication` capability). The boot
  screen copies its terminal (`plymouth/src/boot.html`): keep the two in step.
- `anerti.workspaces`: the Vault-Tec wedge, which is also the bar's `centerAnchor` and stands in
  for the Omarchy menu button.
- `anerti.{agents,audio,bluetooth,clock,monitor,network,power,weather}`: status panels with Vault Boy art.

Generated plugin files, rebuilt from:
- `plugins/anerti.lock/assets/please-stand-by.jpg` (greyscale, tinted at runtime):
  `tools/build-standby` from `tools/please-stand-by.jpg` (the green original, `magick`).
- The logo copies in `anerti.lock`, `anerti.menu`, `anerti.workspaces` (ink) and
  `plymouth/src/`: the theme's `tools/build-logo`, run with `TERMINAL_PROTOCOL_CONTROLLER_DIR`
  set to this checkout.

## Boot screen

`plymouth/vault-tec/*` and `plymouth/preview-*.png` are generated from `plymouth/src/*` by
`tools/build-plymouth` (headless `chromium`, `magick`). It measures every piece from the
rendered mockup and writes the 1080p layout into `vault-tec.script` at `#@LAYOUT@`. Change
layout in `boot.html`, not in the generated script. The lock stage copies `anerti.lock`'s
terminal (keep the two in step), and its banner lines (versions, copyright, hostname) and the
init stage's footer are drawn at install time by `render-footer`, not baked in.

`bin/vault-tec-plymouth install` uses **sudo**, copies to
`/usr/share/plymouth/themes/vault-tec`, adds an initcpio hook (`render-footer` per
initramfs) and a pacman hook (rebuild on Omarchy upgrades and kernel installs), then
rebuilds the initramfs (`limine-mkinitcpio`). It only writes what changed, so re-running it
on a current install does no work and rebuilds nothing. The first install records the
default theme; `uninstall` restores that one (Omarchy's `omarchy` when there is no record).
`test` previews it from a text console with the passphrase `omarchy`. Omarchy's "set boot
screen from theme" menu item (`omarchy-plymouth-set-by-theme`) switches the default back to
`omarchy`; `omarchy theme set` does not.

## Conventions

- Bash scripts open with a header comment that says what the script does and why, and ends
  with a `Usage:` line. Paths come from `ROOT="$(cd "$(dirname "$0")/.." && pwd)"`. They
  dispatch verb subcommands in a final `case` that prints usage to stderr and exits 1.
- Installers are idempotent and only do work when the target differs: compare with
  `cmp`/`diff`, check state before enabling.
- Python tools: `#!/usr/bin/env python3`, stdlib only, `ROOT` from `__file__`, shell out to
  `magick` / `chromium` / `rsvg-convert` via `subprocess.run(check=True)`.
- Comments explain why, in full sentences.
- QML follows the built-in panels (`/usr/share/omarchy/shell/plugins/panels/bluetooth`).
  Use `Panel`, `BarIconButton`, `KeyboardPanel`, `PanelKeyCatcher`, `Toggle` and
  `PanelSeparator` from `qs.Ui`, and colours from `root.bar`.
- Create a new panel with `tools/clone-panel <omarchy.id> "<Vault-Tec name>"`. Like
  `omarchy plugin clone`, it keeps the internal ids so IPC still routes through
  `clonedFrom`, and it adds `PanelArt.qml`.
- `PanelArt.qml` is identical in all eight panels and this plugin (GIF tinted in the active
  theme's foreground, with a glow of it). Change it in every copy, or the copies will diverge.
- `ShareTechMono-Regular.ttf` is duplicated in `anerti.{lock,workspaces}` because
  each plugin is installed standalone.
- `RollWipe.qml` is identical in `anerti.menu` and `anerti.workspaces`. Keep the two copies
  in sync.
- `ThemePalette.qml` is identical in `anerti.{lock,menu,workspaces}`: it reads the active
  theme's `bright_foreground`, `dark_background` and `lighter_background` from its
  `colors.toml`, which the shell's `Color` does not expose.
- To add a part:
  1. Add a `case` branch in `set_part` and a field in `status`.
  2. Add an entry in `Panel.qml`'s `parts`.
  3. Add the part to the usage strings, the README table and `tests/dry-run`.

## Verifying

- `bash -n bin/terminal-protocol-controller` and `tests/dry-run`. Both are safe and never touch the desktop.
- `bin/terminal-protocol-controller status` is read-only.
- Boot screen: `tools/build-plymouth --check` (read-only); after a rebuild, look at
  `plymouth/preview-{lock,init}.png` and preview it with `bin/vault-tec-plymouth test`
  (needs a text console).
- `omarchy plugin validate .`
- A theme plugin: reinstall the one you changed with `bin/vault-tec-plugins install <id>`
  (restarts the shell, so ask first), then check it in the live shell.
- To try a change live, copy it into the shell with
  `rsync -a --delete ./ ~/.config/omarchy/plugins/anerti.terminal-protocol-controller/`. The shell logs
  "reloading", but it keeps the cached `Panel.qml`, and `rescanPlugins` does not clear it.
  Only `omarchy restart shell` shows QML changes (ask first). Then check the log with `journalctl --user -t omarchy-shell --since -1min`. Open the popup with
  `omarchy-shell anerti.terminal-protocol-controller open`.

## Safety

- Ask before running `bin/terminal-protocol-controller set ...` for a real part. The plugin switches restart
  the shell, and `login` uses sudo and rebuilds the initramfs: the boot screen is where the
  LUKS passphrase is entered. `crt` is the only switch that is harmless to round-trip.
- Never install the boot screen without `tools/build-plymouth` having produced a complete
  `plymouth/vault-tec/`.
- Never edit `/usr/share/omarchy/`.
