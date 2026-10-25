# dotfiles (server branch)

The minimal, static variant of the dotfiles for servers: bash, tmux, Neovim and git, in the
TokyoNight Moon palette. Nothing is fetched at runtime (no plugin manager, no tpm, no fisher), so
a host needs only the packages below. The full desktop setup lives on `main`; this branch is
cut from it and meant to be merged from `main` now and then.

Needs `bash`, `git`, `tmux` 3.2+ and `nvim` 0.10+ (Debian 13 ships tmux 3.5a and nvim 0.10.4).

## Use

```sh
git clone -b server https://github.com/XIIISins/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh -n          # dry run: shows what would be backed up and linked
./install.sh             # link everything (existing dirs are backed up)
./install.sh status      # what is linked
./install.sh hooks       # re-run post-link steps (the ~/.bashrc source line, the git hook)
./install.sh unlink tmux # replace the symlink with a real copy of the files
```

Existing directories are moved to `<name>.bak-<timestamp>`. Each `config/<name>` is symlinked
into `$XDG_CONFIG_HOME` (default `~/.config`), so editing a live config edits the repo.

`link` and `hooks` also set `core.hooksPath` to `.githooks`, which enables the pre-commit hook:
gitleaks on the staged changes, then per language on the staged files: shellcheck (sh), `luajit -bl`
(lua), `jq` (json), yamllint (yaml), `palette/render --check` and a `tmux source-file -n` parse.
A missing tool is skipped with a notice. `.githooks/pre-commit --all` checks every tracked file.

## Layout

- `shell`: `bashrc`, sourced from `~/.bashrc` by `install.sh` (one appended line). History,
  PATH, aliases, `EDITOR`, and a prompt with the git branch in the palette colours.
- `tmux`: the same keys as on `main` (backtick prefix, vim pane keys, resize mode), without
  plugins, popups or clipboard tools. Yanks go through OSC 52 to the terminal you ssh from.
- `nvim`: no plugins. Options and keymaps as on `main`, built-in syntax highlighting (yaml, shell
  and python get indent and dialect settings in `config/filetypes.lua`), and small Lua versions of
  the sidebar (`<leader>e`, files only), buffer groups, tabline and statusline.
- `git`: aliases only. Identity and signing live in `config.local` (untracked), see
  `config.local.example`.
- `palette`: the colours as data (`tokyonight-moon.palette`) and `render`, which writes
  `out/` for tmux, sh and Lua. Edit the palette, run `config/palette/render`, never edit `out/`.
  `render --check` fails if `out/` is stale.

## Theming

TokyoNight Moon (credits: [Tokyo Night][tokyo-night] by enkia, the Moon variant from
[folke/tokyonight.nvim][tokyonight-nvim]). tmux and the prompt read `palette/out/`; nvim sets
its own highlight groups from `palette/out/tokyonight-moon.lua` in `config/theme.lua`.

[tokyo-night]: https://github.com/enkia/tokyo-night-vscode-theme
[tokyonight-nvim]: https://github.com/folke/tokyonight.nvim

## Not tracked, on purpose

- `git/config.local`: identity and signing, per machine.
- Anything with credentials or app state.
