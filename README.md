# Vault-Tec Control

An Omarchy shell plugin for the [Dark Terminal Protocol](https://github.com/Anerti/omarchy-dark-terminal-protocol-theme) theme. It adds a radiation icon to the right of the bar. Click it to get one switch for each part that the theme's `full-theme.sh` sets up:

| Switch | What it does |
| ------ | ------------ |
| Menu bar | Vault-Tec wedge and Vault Boy status panels, or the built-in bar |
| Menu | Pip-Boy menu, or the Omarchy menu |
| Mouse cursor | VaultTec cursors, or the cursor you had before |
| CRT effect | Scanlines and vignette screen shader |
| Unlock screen | RobCo terminal lock screen, or Omarchy's |
| Login screen | Terminal boot screen, or the previous one. Opens a terminal for your sudo password, then rebuilds the initramfs |

If the theme is missing, the plugin clones it into `~/.config/omarchy/themes/dark-terminal-protocol` when it loads.

## Install

```bash
omarchy plugin add <this-repo-url> --enable
```

Or by hand:

```bash
rsync -a ./ ~/.config/omarchy/plugins/anerti.vault-tec/
omarchy-shell shell rescanPlugins
omarchy plugin enable anerti.vault-tec --section right
```

## How it works

`bin/vault-tec` does the work, and `Panel.qml` only displays its state:

```bash
bin/vault-tec status                                      # JSON: installed, busy, bar, menu, cursor, crt, unlock, login
bin/vault-tec install                                     # clone the theme if missing
bin/vault-tec set <bar|menu|cursor|crt|unlock|login> <on|off>
```

Each switch runs the same steps as `full-theme.sh` through its `__run` entry point, then restarts the shell. Like `full-theme.sh`, switching the bar or the menu also lays the bar out again. Switches are queued one at a time. Logs go to `~/.cache/vault-tec/full-theme.log`.

`tests/dry-run` checks each switch against a stub theme without touching the desktop.
