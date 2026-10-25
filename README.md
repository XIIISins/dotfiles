# dotfiles

Configs for fish, tmux, Ghostty, Hammerspoon, Karabiner, Neovim, lazygit and
git. Everything lives in `config/`, which mirrors `~/.config`; `install.sh`
symlinks each directory into place, so editing a config edits the repo.

## Use

```sh
./install.sh -n          # dry run: shows what would be backed up and linked
./install.sh             # link everything (existing dirs are backed up)
./install.sh status      # what is linked
./install.sh link tmux   # one package only
./install.sh hooks       # re-run post-link steps (Hammerspoon path, Claude plugins, Zen profile links)
./install.sh unlink fish # replace the symlink with a real copy of the files
./install.sh --server    # server: switch this fresh clone to the `server` branch and install that
```

`--server` is for a fresh clone on a server (bash, tmux, nvim and git only). It refuses to run in a
checkout that is already linked into `~/.config` or has uncommitted changes, since switching
branches would rewrite the live configs.

Existing directories are moved to `<name>.bak-<timestamp>`.

`link` and `hooks` also set `core.hooksPath` to `.githooks`, which enables the pre-commit hook: gitleaks
on the staged changes, then per language on the staged files: shellcheck (sh), `fish_indent --check` and
`fish -n` (fish), `luajit -bl` (lua), `jq` (json), yamllint (yaml), `node --check` (js), `tsc` (usage-band),
`palette/render --check` and a `tmux source-file -n` parse. A missing tool is skipped with a notice.
`.githooks/pre-commit --all` checks every tracked file.

`hammerspoon`, `karabiner` and `zen` are skipped outside macOS. On first link,
machine-local files that are gitignored (fish_variables, tmux plugins,
symlinks into other repos, ...) are copied from the old directory into the
repo directory so nothing breaks. The backup stays complete.

## Layout

- `fish`: `config.fish` sources `config-osx.fish` / `config-linux.fish` /
  `config-windows.fish`, then `~/.config/local/fish/config.fish` if present
  (machine-local, outside the repo; the old `config-local.fish` is still
  read). Plugins are listed in `fish_plugins`, each pinned to a tag or
  commit (`owner/repo@ref`); `fisher_outdated` shows which pins are behind
  upstream (tag pins against the newest tag, commit pins against HEAD), and
  an interactive shell runs it weekly in the background and prints the result
  on the next start. Plugin files are not tracked: on a fresh machine the
  first interactive shell installs fisher (pinned), runs `fisher update`,
  applies `tide-settings.fish` and restarts. Needs `curl`, `git` and network.
  Abbreviations (git, systemctl, docker, kubectl) are in `config.fish` and need
  fish 3.6+. The `fzf_*` functions are fzf pickers with a short abbreviation
  each: `fb` git branch, `fw` git worktree, `fsh` ssh host (from
  `~/.ssh/config` and `config.d/`), `fdk` docker container
  (`sh`/`logs`/`restart`/`stop`), `fkx` kube context or namespace, `fsd` systemd
  service (`status`/`logs`/`restart`/`stop`/`edit`). The docker, kube and systemd
  ones are only set up when the tool is installed.
- `tmux`: plugins are installed by tpm; `tmux.conf` clones tpm and installs
  them on a fresh machine (needs git). `notify.sh` is the notch-style
  notification popup. `layouts.sh` is the named layout selector (prefix `a`
  picks, prefix `A` saves the current layout); the layouts are kept in
  `layouts` and need tmux 3.8 (JSON layout strings).
- `palette`: the TokyoNight Moon colours as data (`tokyonight-moon.palette`)
  plus `render`, a POSIX sh/awk script that turns it into each tool's format
  using the templates in `formats/` (fish, tmux, sh, css). The output in
  `out/` is committed, so nothing needs `render` at runtime. After editing the
  palette or a template, run `config/palette/render`; `render --check` fails
  if `out/` is stale. To support another tool, add `formats/<name>.tmpl`
  (header comment in `render` explains the format).
- `ghostty`: `keybinds` is pulled in from `config` and unbinds Ghostty's
  split/tab keys.
- `hammerspoon`: window focus and the Cmd+Return swallow. `install.sh` points
  Hammerspoon at this directory.
- `karabiner`: Caps Lock to Ctrl and the Aero 75 device entry. Karabiner
  rewrites `karabiner.json` itself, so expect small diffs.
- `git`: aliases and `push.autoSetupRemote`. Identity, 1Password SSH
  signing, credentials and per-directory identities (`includeIf`) live in
  `~/.config/local/git/config`, included last; see `config.local.example`.
  The old `config.local` is still read. Keep `~/.gitconfig` absent: git
  reads it too, so it would silently add to these settings.
- `claude-mods`: a local Claude Code plugin marketplace (`xiiisins-mods`).
  Claude Code keeps plugins in `~/.claude`, so linking this package also
  runs `claude plugin marketplace add` and `claude plugin install` for it
  (needs `claude` on the PATH, and a fresh link; otherwise run the same two
  commands by hand). `usage-band` draws context, rate-limit and cost bars
  above the prompt in the palette colours. The installed copy is a snapshot:
  after editing, `claude plugin update usage-band@xiiisins-mods` and restart.
  `usage-band/.claude-plugin/types/` (what `tsconfig.json` extends) is written by
  Claude Code and gitignores itself, so typechecking works only where Claude Code
  has generated it.
- `fastfetch`: `config.jsonc` with a one-colour logo in the palette blue and
  a trimmed module list (no kernel, display, font, cursor, IP, power adapter,
  window manager or locale). Terminal names the real terminal app even inside
  tmux, and Theme is the Ghostty theme.
- `zen`: `userChrome.css` (TokyoNight Moon, see Theming), `user.js` (an allowlist of the prefs I chose; Zen reapplies it on
  every start) and `zen-keyboard-shortcuts.json` (Zen rewrites it itself, so
  expect diffs). Zen keeps these in a per-machine profile, so linking the
  package also symlinks both files into the install's default profile (macOS
  only; restart Zen after). Never copy `prefs.js` in: it is ids, timestamps and
  migration state. Not tracked: sessions, containers, handlers, and the
  extensions themselves (reinstall by hand: uBlock Origin, Dark Reader,
  Tampermonkey, Tab Session Manager, BetterTTV, Proton VPN, a new tab URL
  extension).
- `nvim`: LazyVim. The dashboard header is read from
  `~/.config/local/nvim/dashboard-header.txt` if it exists (see Not
  tracked), otherwise it is the built-in one.
- `lazygit`: plain config.

## Theming

Everything uses **TokyoNight Moon** so tools match.

Credits: [Tokyo Night][tokyo-night] was created by enkia. The Moon variant
(one of the `night`, `storm`, `moon` and `day` styles) comes from
[folke/tokyonight.nvim][tokyonight-nvim] by Folke Lemaitre, whose extras also
supply the Ghostty theme.

[tokyo-night]: https://github.com/enkia/tokyo-night-vscode-theme
[tokyonight-nvim]: https://github.com/folke/tokyonight.nvim

- ghostty: `theme = "TokyoNight Moon"` (`config/ghostty/config`)
- nvim: `folke/tokyonight.nvim`, `style = "moon"`, transparent so the ghostty
  background shows through (`config/nvim/lua/plugins/colorscheme.lua`). In
  Lua, get colors from `require("tokyonight.colors").setup({ style = "moon" })`
  rather than hardcoding hex (see `config/nvim/lua/config/tabline.lua`,
  `sidebar.lua`).
- tmux: `theme.conf` and `statusline.conf` use `${TN_*}` variables (`${TN_BLUE}`,
  `${TN_BG_DARK}`, ...) from `palette/out/tokyonight-moon.tmux`, which
  `tmux.conf` sources first. tmux only expands them in double-quoted strings
  of files sourced after the palette, so new colours go in those files, not
  in `tmux.conf` itself. `notify.sh` reads `palette/out/tokyonight-moon.sh`
  (`$TN_BG`, `$TN_BG_RGB`, ...). Needs tmux 3.2+ (`%hidden`).
- zen: `config/zen/userChrome.css` imports `palette/out/tokyonight-moon.css`
  and sets Zen's primary colour and dark base from the palette (Zen derives
  the rest). It needs `toolkit.legacyUserProfileCustomizations.stylesheets`,
  which `user.js` turns on. Web content is not themed (Dark Reader does that).
  `install.sh` links both css files into the profile's `chrome/`.
- fish (tide, Rainbow style): `config/fish/conf.d/tide_theme.fish` sets the
  `tide_*` colours as globals from `palette/out/tokyonight-moon.fish`. They
  override the stock values in `tide-settings.fish`, so `tide configure` plus
  regenerating that file does not undo the theme.

The palette table below mirrors `config/palette/tokyonight-moon.palette`,
which is the source of truth.

### Palette

| Name         | Hex       | Typical use                     |
| ------------ | --------- | ------------------------------- |
| bg           | `#222436` | main background                 |
| bg_dark      | `#1e2030` | status bar, sidebars            |
| bg_highlight | `#2f334d` | pane borders, subtle highlight  |
| fg           | `#c8d3f5` | main text                       |
| fg_dark      | `#828bb8` | status text, inactive items     |
| comment      | `#636da6` | comments, muted text            |
| blue         | `#82aaff` | primary accent, active border   |
| cyan         | `#86e1fc` | window index                    |
| green        | `#c3e88d` |                                 |
| magenta      | `#c099ff` |                                 |
| orange       | `#ff966c` | resize mode, active pane number |
| red          | `#ff757f` |                                 |
| yellow       | `#ffc777` |                                 |

Extra values in the palette file that are not in the base palette (used by tmux and fzf):

| Hex       | Use                                                |
| --------- | -------------------------------------------------- |
| `#3b4261` | status segment background (tokyonight `fg_gutter`) |
| `#2d3f76` | copy-mode selection background                     |
| `#6c77a6` | dimmed text of inactive panes                      |
| `#000000` | message "notch" background                         |

## Not tracked, on purpose

- `fish/fish_variables`: universal variables, including tide's prompt
  caches. The tide settings are exported to `fish/tide-settings.fish`; after
  changing the prompt with `tide configure`, regenerate it:

  ```sh
  fish -c 'for v in (set -U --names | string match -r "^tide_\\S+" | sort)
    echo set -U $v (string escape -- $$v)
  end' > config/fish/tide-settings.fish
  ```

- fisher-installed plugin files (tide, fzf.fish, nvm.fish, fisher): listed
  in `.gitignore`, restored by `fisher update`.
- Symlinks into other repos: carried across on first link; list them in
  `.git/info/exclude` to keep them out of `git status`.
- `tmux/plugins/`, `karabiner/automatic_backups/`: third-party or generated.
- `~/.config/local/<tool>/`: per-machine overrides that should not be in a
  public repo: `fish/config.fish`, `git/config` (identity, signing,
  credentials) and `nvim/dashboard-header.txt` (e.g. a work banner). It is
  not a package, so `install.sh` never links or backs it up; create it by
  hand. `fish/config-local.fish` and `git/config.local` in the repo are the
  old places, still read and ignored until every machine has moved.
- Anything with credentials or app state (`gh`, `op`, `1Password`, `rclone`,
  `envman`, `raycast`, ...).

## Adding a package

1. Copy it to `config/<name>/` and add anything machine-local to
   `.gitignore`.
2. Add the name to `packages` in `install.sh`. If it is OS-specific, add it
   to `only_on`; if it has machine-local files, add them to `local_paths`.
