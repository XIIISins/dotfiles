# Handover: dotfiles work in progress

Temporary file for picking the work up on another machine. Not part of the
dotfiles: don't merge this branch (`docs/repo_handover`); delete it locally and
on the remote once you are done with it.

Written 2026-10-26 on the work laptop, on top of `main` at `abb3619` (PR #61).
Everything listed as done below is merged into `main`.

## Done today

| PR | What |
| --- | --- |
| #47 | fish: git abbreviations (`g gst ga gc gd gds gl gp gpl gf gsw gsc`), `!!`, pickers `fb` (branch), `fw` (worktree), `fsh` (ssh), and Ctrl+S for an ssh host (runs `ssh <host>` on an empty line, inserts the host otherwise; follows `Include`) |
| #48 | Claude Code repo hook: `.claude/settings.json` runs `.claude/hooks/check-edit` after every Edit/Write, i.e. `.githooks/pre-commit --files <path>` plus an `install.sh` package check under `config/<name>/`. Also: the usage-band typecheck skips where Claude Code hasn't generated its types |
| #49 | `/ship:ship` skill (plugin `ship` in `config/claude-mods`): the CLAUDE.md shipping routine, user-invoked only |
| #50 | git defaults (`rerere`, `pull.rebase`, `fetch.prune`, histogram, zdiff3, autosquash) and delta as pager, lazygit included |
| #51 | tmux popups (lazygit on `prefix g`) styled from the palette instead of tmux 3.8's grey default theme |
| #52-#61 | other sessions: bat theme, `~/.config/local` overrides for tmux and ghostty, `netbox_ssh` (+ roles, Skip), fzf_ssh grouped by role, one fzf layout for all pickers, Ctrl+G for zoxide `zi`, usage-band type fixes |

## To do on the new machine

1. Pull `main`, then load what changed: new fish shell, tmux `prefix + r`,
   restart Claude Code (the repo hook only loads at session start; approve it
   in `/hooks` if asked).
2. Install the new plugin:
   `claude plugin marketplace update xiiisins-mods` then
   `claude plugin install ship@xiiisins-mods` (or `./install.sh hooks`).
3. New package `bat`: `./install.sh -n` then `./install.sh link bat` (it runs
   `bat cache --build`).
4. Machine-local files these features read (none are in the repo):
   - `~/.ssh/config` should `Include` `config.d/*` for `netbox_ssh`'s output,
     plus the per-machine host file (on the work laptop:
     `include config_myron`).
   - `netbox_ssh`: `NETBOX_URL` in `~/.config/local/fish/config.fish`, the
     token in `~/.config/local/fish/netbox-token` (`Bearer <token>`, mode 600),
     optional `~/.config/local/fish/netbox-ssh-roles`. See `netbox_ssh help`.
   - `tsc` for the usage-band typecheck, which also needs the types Claude Code
     generates in `usage-band/.claude-plugin/types/`; without them the
     pre-commit hook skips the check with a notice.
5. The todo list (`~/.local/share/todo.md`) is per machine. Its open items
   are copied below; finished ones were archived to `todo-done.md`.

## Open: `pull.rebase` breaks the "pull" cleanup step

PR #50 set `pull.rebase = true`. A rebase-style pull refuses whenever the
working tree has unstaged changes, even unrelated ones, and the main checkout
usually has another session's work in it (e.g. `config/nvim/lazy-lock.json`).
So `git pull --ff-only` fails during cleanup. The fix is
`git fetch` + `git merge --ff-only origin/main` in two places:

- `CLAUDE.md`, Git > shipping step 5 ("switch to `main`, pull, ...")
- `config/claude-mods/ship/skills/ship/SKILL.md`, step 7 (`git pull --ff-only`),
  then bump the plugin version and `claude plugin update ship@xiiisins-mods`.

## Todo list (from the work laptop)

```
- [ ] sync ssh config from NetBox (API) as the source of truth: generate an Included file like ~/.ssh/config_myron (machine-local, outside the repo); ctrl+s/fsh already follow Include #ssh
```

`netbox_ssh` (#55-#57) now does most of this, writing `~/.ssh/config.d/netbox`.
Check whether anything is left (e.g. retiring the hand-kept `config_myron`)
before closing it.

## Not decided yet

From the first handover's suggestions (`git show ba3a107:HANDOVER.md`), these
were never discussed:

- A session-per-project tmux switcher (`sesh`, or fish over
  `tmux list-sessions` and the repo dirs); `ide` covers part of it.
- More `display-popup` bindings: a scratch shell, the todo list. The global
  popup style from #51 now applies to them for free.
- A `note`/`log` fish function appending timestamped lines to a daily file,
  next to `todo`.
- `mosh` for flaky links.
- Tide segments on the local prompt: ssh host, kube context, a prod/staging
  colour (needs `tide configure`, then regenerate `tide-settings.fish`, see
  README "Not tracked, on purpose").

Rejected, don't bring back: atuin, tmux-resurrect/continuum, a btop popup,
tide/fish on servers (bash there), ssh `ControlMaster` and similar settings
(added by hand), `op run`, the `wt` helper, `git absorb`/fixup.

Zoxide's `zi` got Ctrl+G in #60, so that question is answered.

## Things learned

- AeroSpace (`~/.config/aerospace/aerospace.toml`, not in the repo) binds
  ctrl-h/j/k/l, ctrl-shift-arrows, alt-h/j/k/l, ctrl-1..7 and alt-tab globally.
  That swallows tmux `C-S-Left/Right` (swap window), nvim `<C-j>`, `<C-l>`,
  `<M-l>` and LazyVim's window and line-move keys. Hammerspoon's cmd+ctrl+hjkl
  doesn't clash but duplicates it. Not acted on.
- Ghostty on macOS doesn't send Option as Alt here, so ctrl+alt bindings
  (fzf.fish's git status/log pickers) never reach fish.
- Your global gitignore (`~/.config/local/git/ignore`) ignores `.claude`; the
  repo's `.gitignore` re-includes `.claude/settings.json` and `.claude/hooks/`.
