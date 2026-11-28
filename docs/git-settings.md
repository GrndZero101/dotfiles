# git settings

What the [`git`](../git) package's
[`config`](../git/.config/git/config) changes in everyday git, and how to
undo any of it on one machine. It assumes the latest git, from Homebrew.

The change most likely to surprise: `git pull` on a branch that has
diverged from its upstream **stops** instead of making a merge commit. Then
pick one: `git pull --rebase` to replay your commits on top, or `git merge`
to merge.

Each line of the config says why it's there. To undo one on a single
machine, set it in that machine's `~/.gitconfig`, which git reads last, so
it wins: for example `git config --global pull.ff true`. To see which file
a setting comes from: `git config --show-origin --get-regexp '^pull\.'`.

## Settings

| Setting | What you'll notice | Off on one machine |
|---|---|---|
| `init.defaultBranch = main` | `git init` starts on `main`, without the hint | `git config --global init.defaultBranch master` |
| `core.pager`, `interactive.diffFilter` | diffs, logs and `git add -p` go through delta, catppuccin-mocha (<kbd>n</kbd> / <kbd>N</kbd> jump between files); plain `less` without delta | `git config --global core.pager less` |
| `merge.conflictStyle = zdiff3` | conflict markers include a `\|\|\|\|\|\|\|` section with the common ancestor, so you see what each side changed | `git config --global merge.conflictStyle merge` |
| `rerere.enabled`, `rerere.autoUpdate` | a conflict you resolved once comes back already resolved and staged; check it with `git diff --cached` before you continue | `git config --global rerere.enabled false` |
| `rebase.autoSquash` | `fixup!` and `squash!` commits move into place in `git rebase -i` | `git config --global rebase.autoSquash false` |
| `rebase.autoStash` | a rebase or `git pull --rebase` with uncommitted changes stashes them first and restores them after | `git config --global rebase.autoStash false` |
| `rebase.updateRefs` | rebasing the top branch of a stack also moves the branches under it | `git config --global rebase.updateRefs false` |
| `pull.ff = only` | `git pull` fast-forwards, or stops when the branch has diverged | `git config --global pull.ff true` |
| `commit.verbose` | the full diff shows under the message in the commit editor | `git config --global commit.verbose false` |
| `diff.colorMoved`, `diff.algorithm = histogram` | moved lines in their own colour; hunks that follow the code's structure | `git config --global diff.colorMoved no` |
| `fetch.prune` | remote branches deleted upstream disappear on the next fetch | `git config --global fetch.prune false` |
| `push.autoSetupRemote` | a new branch's first `git push` sets its upstream; no `-u origin <branch>` | `git config --global push.autoSetupRemote false` |
| `push.followTags` | annotated tags reachable from what you push go up with it | `git config --global push.followTags false` |
| `branch.sort`, `tag.sort` | `git branch` lists the most recent first; `git tag` puts v1.10 after v1.9 | `git config --global branch.sort refname` |
| `help.autoCorrect = prompt` | a mistyped command asks whether to run the one git thinks you meant | `git config --global help.autoCorrect show` |

## Everyday tasks

| Task | Command |
|---|---|
| History as a graph, every branch | `git lg` (one line a commit), `git lg2` (with dates), `git lg3` (with emails) |
| Fix an older commit | `git commit --fixup=<commit>`, then `git rebase -i <commit>~`: the fix is already in place, so save and quit |
| Push after a rebase | `git pushf`: a force push that refuses if the remote has commits you haven't fetched and looked at |
| Branch has diverged on pull | `git pull --rebase`, or `git merge @{u}` |
| Redo a conflict rerere resolved wrongly | `git rerere forget <path>`, then `git checkout -m <path>` to bring the markers back |
| Rebase a stack of branches | check out the top one and rebase it; the branches under it follow (`rebase.updateRefs`) |
