# Handover: fish abbreviations and fzf pickers

Temporary file for picking this branch up on another machine. Delete it before
merging (it is not part of the dotfiles).

Branch: `feat/fish_abbreviations-fzf-pickers`, one commit on top of `main`. Not pushed
as a PR; CLAUDE.md's PR/merge/cleanup steps are still to do.

## What is done

- `config/fish/config.fish`: the `g` alias became an abbreviation, plus git
  abbreviations (`gst ga gc gd gds gl gp gpl gf gsw gsc`), `!!`, and
  tool-guarded `sc jc dk k` (systemctl, journalctl, docker, kubectl).
- `config/fish/functions/fzf_*.fish`, each with a short abbreviation:

  | Abbr | Function | Notes |
  | --- | --- | --- |
  | `fb` | `fzf_git_branch` | switches branch; a remote-only branch gets a tracking local one |
  | `fw` | `fzf_git_worktree` | `cd`s into a worktree |
  | `fsh` | `fzf_ssh` | hosts from `~/.ssh/config` and `~/.ssh/config.d/*`, wildcards skipped |
  | `fdk` | `fzf_docker` | `sh` (default), `logs`, `restart`, `stop` |
  | `fkx` | `fzf_kube` | context, or `ns` for the namespace |
  | `fsd` | `fzf_systemd` | `status` (default), `logs`, `restart`, `stop`, `edit`, `--user` |

- README "Layout" > fish entry describes the above.

## Try it on the laptop

1. Check the branch out (in a worktree, per CLAUDE.md), then open a new fish shell.
   Abbreviations need fish 3.6+.
2. `./install.sh -n` and `./install.sh status` for the linking dry run; do not run
   `./install.sh` without `-n` unless you mean to.
3. In a new shell: type `fb`, `fw`, `fsh` and press space (they expand to the
   function names), then run them.

## Not verified yet

- Verified in a Linux sandbox only: `fish_indent --check`, `fish -n`, and
  `fzf_ssh`, `fzf_git_branch`, `fzf_git_worktree` against a fake ssh config and a
  scratch repo with fzf in `--filter` mode (so the interactive UI and previews
  were never seen).
- Never run: `fzf_docker`, `fzf_kube`, `fzf_systemd` (no kubectl or running
  containers there), and anything on macOS.
- `gitleaks git --staged` could not be run in the sandbox. The changed files were
  scanned with `gitleaks detect --no-git` instead (clean). Run the real command
  before merging.
- `~/.local/share/todo.md` did not exist in the sandbox, so no todo items were
  checked or updated.

## Decisions to make

- Abbreviation names are my pick. Check they do not clash with muscle memory or
  tools on the laptop (`gc`, `gl`, `gp`, `k`, `dk`, `fb`, `fw`).
- Whether the pickers should also get key bindings (Ctrl-F is already
  `fzf_change_directory`, Ctrl-O the fzf.fish directory search).
- `fzf_ssh` does not follow `Include` lines outside `~/.ssh/config.d/`.
- The commit has a `Claude-Session:` trailer and no `Co-Authored-By`; amend if
  you want it gone.

## Options we did not do yet

From the workflow suggestions, roughly by payoff:

**Shell**
- `atuin` (or fzf history with host/cwd context) for searchable history.
- `zoxide` is already initialised in `config.fish`; the only open question is
  whether `z`/`zi` are in use.

**tmux**
- `tmux-resurrect` and `tmux-continuum` for sessions that survive a reboot.
- A session-per-project switcher (`sesh`, or a fish function over
  `tmux list-sessions` plus the repo dirs; `ide` already covers part of this).
- A `synchronize-panes` toggle (e.g. `bind S setw synchronize-panes`), shown in
  the statusline when on.
- `display-popup` bindings for lazygit, `btop`, a scratch shell, the todo list.
  Check `config/tmux/tmux.conf` for free keys first.

**Git**
- Config in `config/git/config`: `rerere.enabled`, `pull.rebase`, `fetch.prune`,
  `diff.algorithm = histogram`, `merge.conflictstyle = zdiff3`,
  `rebase.autosquash`.
- `git absorb` or `--fixup` with autosquash.
- `delta` or `difftastic` as the pager (lazygit config too).

**Sysadmin**
- Tide prompt: show ssh host, kube context and a prod/staging colour. Needs
  `tide configure` and then regenerating `tide-settings.fish` (README "Not
  tracked, on purpose").
- `~/.ssh/config` with `ControlMaster`/`ControlPersist`, `ServerAliveInterval`,
  per-environment `Include`s; `mosh` for flaky links. Machine-local, so it lives
  outside the repo.
- A `note`/`log` fish function appending timestamped lines to a daily file,
  next to `todo`.
- Secrets via `op run --env-file` so nothing lands in history or env files.

**Claude and agent workflow**
- A `/ship` skill in `config/claude-mods` doing the CLAUDE.md git routine
  (gitleaks, branch name, PR, merge, cleanup).
- A hook or skill running `./install.sh -n`, `config/palette/render --check` and
  the linters after edits under `config/`.
- A fish `wt <type/scope_name>` helper that creates the worktree, `cd`s in and
  opens a tmux window.

## Finishing this branch

1. Delete this file.
2. Run `gitleaks git --staged --no-banner --redact -v` on any further changes.
3. PR against `main`, merge by hand (`gh pr merge <n> --merge`), then switch to
   `main`, pull, and delete the branch locally and on the remote. Remove the
   worktree.
