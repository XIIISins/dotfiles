---
name: ship
description: Ship the session's change end to end - commit on a Conventional Commits branch after a gitleaks scan, push, open a PR, merge it, then delete the branch and remove the worktree. Use only when the user runs /ship:ship.
argument-hint: "[what to ship | PR number]"
disable-model-invocation: true
---

# Ship

Running this is the user's go-ahead to push, open a PR and merge it into the
default branch, for this one change only. Ship what this session changed,
nothing else, and stop at the first step that fails instead of working around
it.

The repo's own rules win. If `CLAUDE.md` (or `AGENTS.md`, `CONTRIBUTING.md`)
has a shipping, git or commit section, read it and follow it wherever it
differs from the defaults below: branch format, merge method, PR body, hooks,
trailers.

## Defaults

- Branch: `<type>/<scope>_<description>`, the type a Conventional Commits one
  (`feat`, `fix`, `refactor`, `docs`, `chore`, ...), the scope the area
  touched (package or directory), the description in kebab-case, e.g.
  `feat/nvim_new-feature-1`.
- Commits: Conventional Commits, `type(scope): summary` in the imperative,
  with a body saying why when that isn't obvious. No `Co-Authored-By`
  trailer.
- PR: title like a commit subject; the body is a short summary of what and
  why. No test plan section (changes are tested locally) and no "Generated
  with Claude Code" line.
- Merge by hand with `gh pr merge <n> --merge` (a merge commit, not squash or
  rebase). Automerge is off.

## Steps

1. **Take stock.** Run `git status --short` and `git branch --show-current`,
   and compare `git rev-parse --git-dir` with `--git-common-dir` to see
   whether this is a worktree. Get the default branch with
   `gh repo view --json defaultBranchRef -q .defaultBranchRef.name`, and see
   whether the branch already has a PR with `gh pr view --json number,state,url`.
   With a PR number as the argument, skip to step 6 for that PR. Text as the
   argument narrows what to ship.

   Work out which changes are this session's: the files you edited.
   Uncommitted changes you did not make belong to another session. Leave them
   unstaged, and don't stash, revert or reformat them. If the split is
   unclear, ask before going on.

2. **Branch.**
   - On a worktree's auto-named branch (e.g. `worktree-<name>`) that has not
     been pushed: rename it with `git branch -m <branch>`.
   - On a branch that is already named properly: keep it.
   - On the default branch: if the repo's rules keep the main checkout there
     (work happens in worktrees), don't switch it. Tell the user the changes
     are in the main checkout and ask how to proceed. Otherwise run
     `git switch -c <branch>`; uncommitted changes come along.

3. **Commit.** Stage by name (`git add <paths>`, never `-A` or `.`). Then run
   `gitleaks git --staged --no-banner --redact -v` if gitleaks is installed.
   If a sandbox blocks running it directly and a pre-commit hook runs it, use
   the hook's run during the commit instead, and check that its output says
   no leaks.
   - On a leak, stop. Remove the secret instead of allowlisting it, and tell
     the user if it was already committed or pushed.
   - Let hooks run; never use `--no-verify`. If a hook fails, fix what it
     reports, re-stage and commit again.
   - Commits already on the branch: check `git log --oneline <default>..HEAD`
     follows the conventions. Don't rewrite history that has been pushed.

4. **Push** with `git push -u origin <branch>`. Never push to the default
   branch, never force-push.

5. **Open the PR** with `gh pr create --base <default> --head <branch>
   --title ... --body ...`. Reuse an open PR for the branch instead of making
   a second one.

6. **Merge.** If the repo has CI, wait for `gh pr checks <n> --watch` and
   stop if a check fails. Then run `gh pr merge <n> --merge`.
   - Never use `--admin` or otherwise bypass branch protection.
   - If a permission prompt is declined or a rule denies the merge, stop and
     report. Don't route around it through another session or another
     command.
   - Confirm with `gh pr view <n> --json state,mergeCommit`.

7. **Clean up** once the PR shows MERGED.
   - **Worktree this session created with `EnterWorktree`:** first check
     `git status` is clean, then `ExitWorktree` with `action: "remove"`. It
     asks for `discard_changes: true` because the branch has commits the
     starting commit lacks; that is fine now that they are merged, never
     before.
   - **Worktree the session did not create:** leave it. Remove it
     (`git worktree remove <path>`, from outside it) only if the user set it
     up for this change; ask if unsure.
   - **Back in the main checkout:** if it is on the shipped branch, run
     `git switch <default>`, then `git pull --ff-only`. Other sessions'
     uncommitted changes stay put. If the pull refuses because of them, stop
     and report.
   - **Delete the branch** with `git branch -d <branch>`. If `-d` refuses,
     find out why instead of using `-D`. Then run
     `git push origin --delete <branch>`, skipping this if the remote already
     deleted it.

8. **Todo.** If an item in the todo list (`$TODO_FILE`, else
   `~/.local/share/todo.md`) is `[~]` with this session's name and matches the
   change, mark it `[x]`. Edit only that line.

9. **Report**:
   - the PR URL and the merge commit,
   - that the branch and worktree are gone,
   - which of other sessions' uncommitted files were left alone,
   - what needs reloading before the change is live (from the repo's rules,
     e.g. a new shell, tmux `prefix + r`, an nvim restart, or a Claude Code
     restart for hooks and plugins).
