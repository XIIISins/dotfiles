---
name: todo
description: Organize the user's flat todo list at ~/.local/share/todo.md. Adds #tag suffixes, merges duplicates, flags stale in-progress items, and asks about whatever it can't place. Use when the user runs /todo:todo or asks to sort, triage or clean up their todo list or ideas.
---

# Todo triage

The list is one flat file, `~/.local/share/todo.md` (`$XDG_DATA_HOME/todo.md`
if set). The user appends to it from a shell with `todo "idea"`, and other
Claude sessions append and mark items too, so edit it carefully.

```
- [ ] open item #tmux
- [~] in progress #nvim (session-name)
- [x] done #fish
```

Tags are `#lowercase-words` at the end of the item text, before any
`(session-name)`. The list stays flat: no headings, no reordering. Tags are
the categories.

## Steps

1. **Read** the file. If it is missing or empty, say so and stop.
2. **Learn the vocabulary.** Collect the tags already in use. Reuse them
   before inventing one. Seed names for new items are the package names under
   `config/` in the dotfiles repo (`fish`, `tmux`, `nvim`, `ghostty`,
   `hammerspoon`, `karabiner`, `lazygit`, `git`, `palette`) plus `claude`,
   `repo` (cross-cutting or CLAUDE.md-level) and `bug`. One tag per item,
   two at most.
3. **Tag what is clear.** Add tags to untagged lines whose area is
   unambiguous. Don't touch the wording of the text.
4. **Check in-progress items.** Run `ListAgents`. A `[~]` item whose session
   name no longer appears is stale: collect it for step 6, don't reset it
   yourself.
5. **Spot duplicates and overlaps.** Exact duplicates (same text apart from
   tags) can be merged into the first one. Anything merely related goes to
   step 6.
6. **Ask once, in a batch**, with `AskUserQuestion` (up to 4 questions per
   call, so group them). Cover:
   - items whose area is unclear, offering the likeliest tags,
   - related-but-not-identical items: merge, keep both, or link,
   - stale `[~]` items: reset to `[ ]`, mark `[x]`, or leave,
   - items that read as several tasks: split or leave.
   Apply the answers; don't re-ask what the user already answered.
7. **Offer to archive** `[x]` items to `todo-done.md` next to the list, and do
   so only if they say yes.
8. **Report** in a few lines: what was tagged, merged, archived, and what is
   still untagged. Then offer to start the top open item (see below).

## Editing rules

- The user appends with `>>` at any time. Make each change a separate small
  `Edit` of one line, re-reading the file first if time has passed, rather
  than rewriting the whole file, so a fresh append is never lost.
- Never delete or reword a line without an explicit yes. Adding a tag and
  merging exact duplicates are the only changes you may make unasked.
- Keep the `- [ ]` / `- [~]` / `- [x]` prefixes exactly, since `todo.fish` and
  other sessions parse them.

## Starting an item

If the user picks one, mark it `[~]` with your session name as `ListAgents`
shows it, then follow the dotfiles repo's own rules (CLAUDE.md): check
`ListAgents` for overlap, work in a worktree when the change doesn't need
live testing, mark `[x]` once it is merged.
