# dotfiles

Configs for fish, tmux, Ghostty, Hammerspoon, Karabiner, Neovim, lazygit and git.
Everything lives in `config/`, which mirrors `~/.config`; `install.sh` symlinks each
directory into place, so editing a config edits the repo.

## Use

```sh
./install.sh -n          # dry run: shows what would be backed up and linked
./install.sh             # link everything (existing dirs are moved to <name>.bak-<timestamp>)
./install.sh status      # what is linked
./install.sh link tmux   # one package only
./install.sh unlink fish # replace the symlink with a real copy of the repo files
```

`hammerspoon` and `karabiner` are skipped outside macOS. On first link, machine-local files
that are gitignored (fish_variables, tmux plugins, symlinks into other repos, ...) are copied from
the old directory into the repo directory so nothing breaks. The backup stays complete.

## Layout

| Package | Notes |
|---|---|
| `fish` | `config.fish` sources `config-osx.fish` / `config-linux.fish` / `config-windows.fish`, then `config-local.fish` if present (machine-local, ignored). Plugins are listed in `fish_plugins` and are not tracked: on a fresh machine the first interactive shell installs fisher (pinned), runs `fisher update`, applies `tide-settings.fish` and restarts. Needs `curl` and network. |
| `tmux` | Plugins are installed by tpm; `tmux.conf` clones tpm and installs them on a fresh machine (needs git). `notify.sh` is the notch-style notification popup. |
| `ghostty` | `keybinds` is pulled in from `config` and unbinds Ghostty's split/tab keys. |
| `hammerspoon` | Window focus and the Cmd+Return swallow. `install.sh` points Hammerspoon at this directory. |
| `karabiner` | Caps Lock to Ctrl and the Aero 75 device entry. Karabiner rewrites `karabiner.json` itself, so expect small diffs. |
| `git` | Aliases only. Identity and 1Password SSH signing live in `config.local` (untracked, copied across on first link); see `config.local.example`. |
| `nvim`, `lazygit` | Plain configs. |

## Not tracked, on purpose

- `fish/fish_variables`: universal variables, including tide's prompt caches. The tide settings are exported to
  `fish/tide-settings.fish`; after changing the prompt with `tide configure`, regenerate it:

  ```sh
  fish -c 'for v in (set -U --names | string match -r "^tide_\\S+" | sort); echo set -U $v (string escape -- $$v); end' > config/fish/tide-settings.fish
  ```
- fisher-installed plugin files (tide, fzf.fish, z, nvm.fish, fisher): listed in `.gitignore`, restored by `fisher update`.
- Symlinks into other repos: carried across on first link; list them in `.git/info/exclude` to keep them out of `git status`.
- `tmux/plugins/`, `karabiner/automatic_backups/`: third-party or generated.
- Anything with credentials or app state (`gh`, `op`, `1Password`, `rclone`, `envman`, `raycast`, ...).

## Adding a package

1. Copy it to `config/<name>/` and add anything machine-local to `.gitignore`.
2. Add the name to `packages` in `install.sh`. If it is OS-specific, add it to `only_on`; if it has
   machine-local files, add them to `local_paths`.
