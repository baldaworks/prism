# Teams, saved state and recovery

Run the same `prism:story` workflow whether you start a change or resume it.
Prism reads the Story's requirements, design, current phase, approval and Tasks
from Beads. You do not need to reconstruct the phase sequence from chat history.
For a known item, give the skill its ID:

```text
$prism:story Continue <story-id>
```

Replace `<story-id>` with the actual ID. Clarification and approval are still
human decisions; resuming is not blanket authorization to implement.
See the [Story contract](../plugins/prism/skills/story/SKILL.md).

## Git multiplayer

There are two histories: source code in Git and work records in Beads/Dolt.
They can share a remote repository, but Dolt data uses `refs/dolt/data`, not
the source branch. Publish and retrieve each history explicitly. A source
`git push` alone does not publish the Beads database.
See [Beads sync concepts](https://github.com/gastownhall/beads/blob/main/docs/core-concepts/sync-concepts.md).

### Join an existing team

Install Prism and the team's supported Beads version first. Obtain the repository
URL and Story ID from a teammate. The following template assumes the team has
already configured and published a Beads remote:

```sh
git clone <team-repository-url> project
cd project
bd bootstrap --dry-run
# Check that the plan restores the expected team data, not an empty workspace.
bd bootstrap
bd dolt remote list
bd show <story-id>
```

Bootstrap can initialize an empty database when no shared history is available.
If the plan does not identify the expected data, stop and ask the team owner
about publishing/restoring it. Do not use force initialization to make a missing
Story disappear. Source: installed Beads 1.1.0 `bd bootstrap --help`; check your
installed version's help for changed options.

### Start a work session

Agree who owns the Story before editing. Update the code using your team's
normal Git branch/review workflow, then retrieve current records:

```sh
git status --short
# Resolve local work before integrating incoming source changes.
git pull --ff-only
bd dolt pull
bd show <story-id>
bd children <story-id>
```

Stop on a source or database conflict. Reconcile requirements, phases and child
status rather than blindly choosing the newest text. Prism's logical Task
assignee records the implementation/review role, not an exclusive distributed
lease. Two disconnected clones can both believe work is ready. Team ownership
and coordination are still necessary.

### Hand off a change

Check the actual diff, test results and Beads records. Commit only reviewed,
completed source changes under repository policy. If your Beads configuration
does not commit every write, checkpoint the database with `bd dolt commit`.
With explicit authorization to publish, use both channels:

```sh
git push
bd dolt push
```

Give the next person the source branch/commit and Story ID, plus any remaining
gate or blocker. If either push fails, the handoff is incomplete: state which
history was published and reconcile before another person continues. Git and
Dolt are not one atomic publication operation. A rollback of code does not
automatically roll back Story state.

These commands describe a team workflow; installing or running Prism does not
automatically configure permissions or grant permission to push. Fresh-clone
onboarding and Dolt push/pull follow the upstream sync guide above.

## Durability and interrupted work

| Event | What survives | What to check next |
| --- | --- | --- |
| Chat ends | Saved Beads records and files on disk | Resume by Story ID; inspect unfinished work. |
| Local history is committed | Git commits and Dolt commits in their respective stores | Neither alone is an off-machine copy. |
| Both histories are published | The remote copies that actually reached their destinations | Confirm the expected branch and Story are available to the recipient. |
| A machine is lost | Only remote data or a usable external backup | Clone code and bootstrap/restore Beads; unpublished work may be lost. |
| A step is interrupted | Whatever was successfully saved before interruption | Code can be ahead of Task status, or vice versa. Reconcile before repeating actions. |

Beads supports configurable Dolt commit policies. Do not assume every write
has a historical checkpoint merely because it is locally visible. Inspect your
version's configuration and `bd dolt commit --help`.

For recovery, begin with read-only inspection:

```sh
bd where
bd dolt status
bd backup status
bd show <story-id>
git status --short
```

Native `bd backup` preserves database state, including history and working-set
data; `bd export` produces issue records for interchange/migration. JSONL export
is not equivalent to full database recovery or Dolt synchronization. A backup
on the same lost disk is not off-machine protection. Agree a backup destination
and test restoration separately; do not overwrite a live workspace to test it.
Sources: Beads 1.1.0 `bd backup --help`, `bd dolt commit --help`, and
[Dolt architecture](https://github.com/gastownhall/beads/blob/main/docs/architecture/dolt.md).

Saved state does not provide exactly-once execution. For example, code may
have changed before its Task was marked complete. The agent must inspect code
and checks rather than repeating an external action just because a record is
still open. Approval belongs to the current item; another teammate's Epic
approval does not approve each child Story.

## Validation layers

| Layer | What it establishes | What it does not establish |
| --- | --- | --- |
| Package integrity | Prism's declared sources, mirrors, packaging and documentation agree | That a particular model followed those instructions |
| Structural artifacts | Data can be read and its recorded structure inspected | That requirements are complete or a dependency is sensible |
| Semantic review | The agent evaluates requirements, design, diff and acceptance evidence | A technically unbypassable permission gate or guaranteed separate reviewer process |
| Application tests | The project's executed checks passed for the tested code | Coverage of all behavior or correctness of untested paths |

Prism's [Apply](../plugins/prism/skills/story/references/apply.md) requires
native checks and an independent logical review pass before Task closure.
[Verify](../plugins/prism/skills/story/references/verify.md) inspects the whole
Story and closes it or returns it to the appropriate phase. Returning to
requirements, design or breakdown clears prior approval.

The repository's [ownership validator](../scripts/validate-lifecycle-ownership.sh)
and [forward fixtures](../scripts/test-lifecycle-forward-contracts.sh) test
Prism's own contracts. They are not a universal live-project validator or proof
of LLM compliance. Use repository permissions and required CI for critical
enforcement. See [the comparison](comparison.md) for how OpenSpec and BMAD
divide these responsibilities.
