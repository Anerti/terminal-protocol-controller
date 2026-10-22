# AGENTS.md

Terminal Protocol Controller: an Omarchy shell plugin (`anerti.terminal-protocol-controller`) that puts a radiation icon in
the bar. Its popup has one switch per part of the
[Dark Terminal Protocol](https://github.com/Anerti/omarchy-dark-terminal-protocol-theme) theme:
menu bar, menu, mouse cursor, CRT effect, unlock (lock) screen, login (boot) screen. If the theme
is missing, the plugin clones it into `~/.config/omarchy/themes/dark-terminal-protocol`.

## Layout

| Path | What it is |
| ---- | ---------- |
| `manifest.json` | Plugin manifest: one `bar-widget`, entry point `Panel.qml`, `defaultSection: right`. |
| `Panel.qml` | Bar button and popup. It shows `bin/terminal-protocol-controller status` and starts `bin/terminal-protocol-controller set`, and does no work itself. |
| `RadiationIcon.qml` | The bar and hero icon: `assets/radiation.png` (the Wikimedia radiation warning symbol as a white mask) tinted like the glyph icons. |
| `PanelArt.qml`, `assets/` | The tinted GIF under the popup's hero, shared with the theme's other panels. |
| `bin/terminal-protocol-controller` | Backend: `status` (JSON), `install` (clone the theme), `set <part> <on\|off>`. |
| `tests/dry-run` | Runs every switch against a stub theme and stub `omarchy`/`gsettings`/`plymouth` commands, and checks which steps run. |

## How it works

- **The theme does the work.** `bin/terminal-protocol-controller` calls `full-theme.sh __run <step> args...` (steps
  such as `install_plugins`, `set_plugins`, `enable_builtins`, `place_bar`, `set_cursors`,
  `restart_shell`), or the theme's `bin/vault-tec-*` tools directly. Do not copy that logic
  in here: if a step is missing, add it to the theme.
- **Parts:**
  - `bar`: every theme plugin except `anerti.menu` and `anerti.lock`. The list is computed
    from the theme's `plugins/` folder, as `full-theme.sh` does.
  - `menu`: `anerti.menu`.
  - `unlock`: `anerti.lock`.
  - `login`: the Plymouth theme.
  - `cursor`: VaultTec cursors.
  - `crt`: the shader flag file.
- **The bar layout follows the bar and menu.** After switching `bar` or `menu`, `place_bar`
  reads the new status and lays the bar out for it. Plugin switches end with
  `restart_shell`. `crt`, `cursor` and `login` do not restart the shell.
- **Detached, serialised.** A shell restart kills the shell's child processes, so `Panel.qml`
  starts `set` with `setsid -f`. The backend holds `~/.cache/terminal-protocol-controller/control.lock` while
  a switch or an `install` runs (each monitor's panel runs `install` at load). `status` reports that as `busy`.
- **Optimistic switches.** While a change is in flight, `Panel.qml` keeps the wanted value in
  `pending`. It drops that value once the status matches, or once the backend is idle and
  3 s have passed. The 3 s cover a poll that lands before the backend takes its lock.
- **Login needs sudo.** It opens `omarchy-launch-floating-terminal-with-presentation`, where
  the user types their password. The initramfs is then rebuilt.
- **Auto-download.** At load, if `status` says `installed: false`, the panel runs `install`
  once. After a failure it tries again only the next time the popup opens.
- `TERMINAL_PROTOCOL_THEME_DIR` overrides the theme location. The test uses it.

## Conventions

Follow the theme's own conventions (its `AGENTS.md`):
- Bash scripts open with a header comment that says what the script does and why, and ends
  with a `Usage:` line. They dispatch verb subcommands in a final `case` that prints usage
  to stderr and exits 1.
- Comments explain why, in full sentences.
- QML follows the built-in panels (`/usr/share/omarchy/shell/plugins/panels/bluetooth`).
  Use `Panel`, `BarIconButton`, `KeyboardPanel`, `PanelKeyCatcher`, `Toggle` and
  `PanelSeparator` from `qs.Ui`, and colours from `root.bar`.
- To add a part:
  1. Add a `case` branch in `set_part` and a field in `status`.
  2. Add an entry in `Panel.qml`'s `parts`.
  3. Add the part to the usage strings, the README table and `tests/dry-run`.

## Verifying

- `bash -n bin/terminal-protocol-controller` and `tests/dry-run`. Both are safe and never touch the desktop.
- `bin/terminal-protocol-controller status` is read-only. Compare its output with the theme's `full-theme.sh --status`.
- `omarchy plugin validate .`
- To try a change live, copy it into the shell with
  `rsync -a --delete ./ ~/.config/omarchy/plugins/anerti.terminal-protocol-controller/`. The shell logs
  "reloading", but it keeps the cached `Panel.qml`, and `rescanPlugins` does not clear it.
  Only `omarchy restart shell` shows QML changes (ask first). Then check the log with `journalctl --user -t omarchy-shell --since -1min`. Open the popup with
  `omarchy-shell anerti.terminal-protocol-controller open`.

## Safety

- Ask before running `bin/terminal-protocol-controller set ...` for a real part. The plugin switches restart
  the shell, and `login` uses sudo and rebuilds the initramfs: the boot screen is where the
  LUKS passphrase is entered. `crt` is the only switch that is harmless to round-trip.
- Never edit `/usr/share/omarchy/`.
