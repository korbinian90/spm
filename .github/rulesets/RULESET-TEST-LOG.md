# `main-required-checks` ruleset: verification log

Everything below was tested on **korbinian90/spm** (a fork). **spm/spm was not modified.**

Date: 2026-08-05. All times UTC.

Companion file: [`main-required-checks.json`](main-required-checks.json), ready for
Settings -> Rules -> Rulesets -> "New ruleset" -> "Import a ruleset".

---

## 1. Audit of both repositories (before any change)

| | korbinian90/spm | spm/spm |
|---|---|---|
| `allow_auto_merge` | true | true |
| `allow_squash_merge` | true | true |
| `allow_merge_commit` | true | false |
| `allow_rebase_merge` | true | true |
| `delete_branch_on_merge` | false | true |
| Default branch | `main` | `main` |
| Rulesets | none | none |
| Org/enterprise rulesets applying to `main` | none | none |
| Plan | Free (personal) | **Team** |

**Classic branch protection on `main`**

- **spm/spm: no `required_status_checks`.** Only `required_linear_history: true`,
  force-push and deletion disabled, `enforce_admins: false`. No required reviews.
  The stop condition for this piece of work was therefore not met and the bypass
  design is viable.
- korbinian90/spm had `required_pull_request_reviews` with
  `required_approving_review_count: 1`. Removed for the duration of the test so it
  could not mask ruleset behaviour. Backed up first; contents recorded in section 8.

**Live check names on a recent spm/spm PR** (#151, head `317a80e4b`):

| Check | App | App id |
|---|---|---|
| **`Tests passed`** | `github-actions` | **15368** |
| `CLAAssistant` | `github-actions` | 15368 |
| `Configure test matrix (PR uses limited MATLAB versions)` | `github-actions` | 15368 |
| `Run MATLAB Tests (latest, ubuntu-latest)` and 4 more matrix names | `github-actions` | 15368 |

There are **no commit statuses** on spm/spm, only check runs.

**Secrets**

- `PAT_FIELDTRIP_SYNC` exists on **spm/spm only**. It is not set on the fork, which is
  why fork PR #5 was opened by `app/github-actions` through the `GITHUB_TOKEN`
  fallback and carries zero check runs (GITHUB_TOKEN-authored PRs do not trigger
  workflows).
- The account behind `PAT_FIELDTRIP_SYNC` is **SPMcentral**.

**SPMcentral's standing in the spm org**

- `admin` on spm/spm
- **org owner** of `spm`
- **maintainer** of `spm-staff`, the only team with repository access (`push`)

This matters, and section 5 covers it in detail.

---

## 2. Test rig

Because MATLAB and `spm-tests-data` are far too slow for this kind of iteration, a
stub workflow published a check with **exactly** the name `Tests passed`, mirroring
the `tests-passed` aggregator job in `matlab.yml` (same `needs:` plus `if: always()`
shape). The real `Tests` workflow was already `disabled_manually` on the fork, so the
name was never published twice.

Verified identical to production:

```
Tests passed    app=github-actions/id=15368    success
```

Full stub run: 10:56:56Z to 10:57:48Z (**52 seconds**).

The outcome was driven by `.github/ruleset-test-outcome`:

| Value | Behaviour |
|---|---|
| `pass` | both stub shards succeed, `Tests passed` reports success |
| `fail` | one shard fails, `Tests passed` reports failure |
| `partial` | one shard hangs, so `Tests passed` never starts and the required context stays unreported |

---

## 3. Results

Ruleset under test: target default branch, one `required_status_checks` rule with
context `Tests passed` pinned to `integration_id: 15368`.

> `enforcement: "evaluate"` was **rejected**: `Enforcement evaluate option is not
> supported on this plan. Please upgrade to Enterprise to enable it.` The spm org is
> on the **Team** plan, so evaluate mode is unavailable there too. Every test below
> therefore ran in `active` mode, and `disabled` was verified as the staging
> substitute (T8).

| # | Scenario | Bypass | Expected | Result |
|---|---|---|---|---|
| T1 | Direct push to `main` | empty | rejected | **PASS** |
| T2 | Direct push to `main` | Write role | accepted | **PASS** |
| T3 | PR, `Tests passed` succeeds | empty | auto-merge fires after check | **PASS** |
| T4 | PR, `Tests passed` fails | empty | blocked indefinitely | **PASS** |
| T5 | PR, `Tests passed` never reported | empty | blocked indefinitely | **PASS** |
| T6 | PR by a **bypassing** actor, check fails | Write role | see section 5 | **see 5** |
| T7 | `--admin` override, check fails | empty | refused | **PASS** |
| T8 | Direct push, `enforcement: disabled` | empty | accepted, not logged | **PASS** |
| T9 | Direct push, re-verify | empty | rejected | **PASS** |
| T10 | PR, re-verify | empty | auto-merge fires after check | **PASS** |
| T11 | Direct push | one named **User** | accepted | **PASS** |
| T12 | Direct push | named User, `bypass_mode: "pull_request"` | rejected | **PASS** |
| T13 | `git push --dry-run` against a blocked ref | empty | reports the violation | **it does not** |
| T14 | Push by the **Actions bot** (GITHUB_TOKEN) | empty | see section 7 | **rejected** |
| T15 | Contents API write to a blocked ref | empty | rejected like a push | **PASS** |
| T16 | `cla-signatures` protection: append / force push / delete | empty | allow / reject / reject | **PASS** |

### T1 - direct push rejected with an empty bypass list

```
remote: error: GH013: Repository rule violations found for refs/heads/main.
remote: - Required status check "Tests passed" is expected.
 ! [remote rejected]     HEAD -> main (push declined due to repository rule violations)
```

On creation with `bypass_actors: []` the API reported `current_user_can_bypass: "never"`
even though the pushing account owns the repository. Rulesets have **no implicit admin
escape hatch**, unlike classic protection's `enforce_admins`.

### T2 - direct push accepted once the Write role is a bypass actor

```
remote: Bypassed rule violations for refs/heads/main:
remote: - Required status check "Tests passed" is expected.
   dca5486e2..4b7315869  HEAD -> main
```

`current_user_can_bypass` flipped to `"always"`. Note the pushing account holds
**admin**, not write, and a **Write**-role bypass still covered it. Repository role
bypass is cumulative: granting Write also grants everyone above it.

### T3 - passing PR auto-merges only after the check goes green

PR #6, auto-merge armed while the check was pending.

```
11:02:39  OPEN/BLOCKED
11:02:55  OPEN/BLOCKED
11:03:10  OPEN/BLOCKED
11:03:26  MERGED     (mergedAt 11:03:23Z, squash)
```

Held roughly 55 seconds, then merged. It did not merge on arming.

### T4 - failing PR never merges

PR #7. `Tests passed` reported FAILURE at 11:05:01Z and the PR was still
`OPEN/BLOCKED` at 11:09:10Z, over five minutes later. Auto-merge stayed armed and
never fired.

### T5 - unreported required check never merges

PR #8, `partial`. One shard hung, so the aggregator never started and `Tests passed`
**never appeared in the check list at all**:

```
11:15:24  OPEN/BLOCKED
    Stub test (2):IN_PROGRESS | Stub test (1):SUCCESS | CLAAssistant:SUCCESS | Read desired outcome:SUCCESS
```

An **absent** required context blocks exactly like a failing one. This is the case
most likely to occur in production, since `matlab.yml` runs a wide matrix and the
aggregator only starts once every leg finishes.

### T7 - `--admin` cannot override an empty bypass list

PR #10, `Tests passed` = FAILURE:

```
$ gh pr merge 10 --squash --admin
GraphQL: Repository rule violations found
Required status check "Tests passed" is failing.
```

With `bypass_actors: []` the rule is absolute. Nobody can override it, including the
repository owner.

### T8 - `disabled` is a true no-op

Direct push accepted silently, with no `Bypassed rule violations` banner and, notably,
**no Rule Insights entry**. `disabled` gives you a parked ruleset but no dry-run
telemetry, so it is a weaker staging tool than `evaluate` would have been.

### T11 - individual people can be bypass actors

`bypass_actors` accepts `actor_type: "User"`. With a **single named user** as the only
bypass entry, and no role or team entry at all, `current_user_can_bypass` reported
`"always"` and the direct push went through:

```
remote: Bypassed rule violations for refs/heads/main:
remote: - Required status check "Tests passed" is expected.
   f3bd1c2d6..e19f6507c  HEAD -> main
```

This is the mechanism to use for a named list of maintainers. It needs no team and no
change to anyone's repository role.

### T12 - `bypass_mode: "pull_request"` does not permit direct push

Same named user, `bypass_mode` changed from `"always"` to `"pull_request"`:

```
current_user_can_bypass: "pull_requests_only"

remote: - Required status check "Tests passed" is expected.
 ! [remote rejected]     HEAD -> main (push declined due to repository rule violations)
```

So `"always"` is the **minimum** grant that allows pushing to `main`, and it
unavoidably carries the `--admin` PR override with it. The two capabilities cannot be
separated. See section 5.

### T13 - `git push --dry-run` does not see the ruleset

Against a `main` that genuinely rejects the push, `--dry-run` reported success:

```
$ git push --dry-run korbinian90 HEAD:main
   43a9cdbdc..878fa0e1a  HEAD -> main
exit=0
```

`main` did not move, and the same push without `--dry-run` was rejected. Ruleset
evaluation happens in the pre-receive hook, which `--dry-run` never reaches. **Do not
use `--dry-run` to check whether someone can push**, it returns a false pass. Use the
`current_user_can_bypass` field on the ruleset instead, which tracked the real outcome
exactly across T1, T2, T9, T11 and T12.

### T14 - the Actions bot is blocked, which breaks the CLA Assistant

See section 7.

### T16 - protecting the signature branch without blocking the bot

Second ruleset, `cla-signatures-protection`: rules `deletion` and `non_fast_forward`,
empty bypass, scoped to `refs/heads/cla-signatures`. Verified on a throwaway branch:

| Operation | Result |
|---|---|
| normal append push (what the CLA bot does) | **accepted** |
| `git push --force` | rejected, `push declined due to repository rule violations` |
| `git push --delete` | rejected, same |

`non_fast_forward` only blocks history rewrites, so the bot's ordinary appends are
unaffected. This is what gives the signature record the same force-push and deletion
protection that `main` has through its classic protection.

### T9 and T10 - re-verified in active mode

After flipping back to `active` with an empty bypass, T1 and T3 were repeated. Direct
push rejected again; PR #11 held `BLOCKED` from 11:29:26Z and merged at 11:30:33Z,
about 67 seconds.

### Rule Insights

Every enforced event was recorded, and the `disabled` push correctly was not:

| Rule suite | Time (UTC) | Result | Test |
|---|---|---|---|
| 3566524909 | 10:59:55 | `fail` | T1 |
| 3566544539 | 11:01:45 | `bypass` | T2 |
| 3566564340 | 11:03:23 | `pass` | T3 |
| 3566789515 | 11:26:02 | `bypass` | T6 `--admin` |
| 3566805924 | 11:27:49 | `fail` | T7 |
| 3566814134 | 11:28:39 | `fail` | T9 |
| 3566830419 | 11:30:23 | `pass` | T10 |

Rule detail is available per suite, for example T1:

```json
{"rule_type": "required_status_checks", "result": "fail",
 "details": "Required status check \"Tests passed\" is expected."}
```

---

## 4. Bypass actor types, and repository role ids

`bypass_actors` accepts `User`, `Team`, `RepositoryRole`, `OrganizationAdmin` and
`DeployKey`. **`User` works** (T11), which is what makes a named maintainer list
possible. `bypass_mode` must be `"always"` for direct push; `"pull_request"` does not
permit it (T12).

If you would rather bypass by role than by name, the role ids follow.

The role ids are **not** a contiguous 1 to 5 range. Probing each id and resolving the
name through GraphQL (`bypassActors.repositoryRoleName`) gave:

| `actor_id` | Role |
|---|---|
| 2 | `maintain` |
| **4** | **`write`** |
| 5 | `admin` |

Ids 1 and 3 were silently rejected and left the ruleset unchanged. **Do not assume
write is 3.** Confirm on spm/spm after import, since an org repo may expose `triage`
as well.

---

## 5. The SPMcentral question, and what testing actually showed

The concern going in was that if the `PAT_FIELDTRIP_SYNC` account is a bypass actor,
`gh pr merge --auto --squash` would merge instantly and the tests would never gate.
That would be a failure that looks like success.

The concern is well founded in one respect: **SPMcentral cannot be excluded from any
conventional bypass target.** It holds admin on spm/spm, owns the org, and sits in
`spm-staff`. So `OrganizationAdmin`, `RepositoryRole: write|maintain|admin`, and the
`spm-staff` team all contain it. `bypass_mode: "pull_request"` does not help; it grants
bypass *on pull requests*, which is the wrong direction entirely.

**But the predicted failure did not reproduce.** T6 tested it directly: a bypass actor
(`current_user_can_bypass: "always"`) opened a fresh PR whose `Tests passed` check
failed, and armed auto-merge before any check reported.

```
11:19:16  auto-merge armed
11:20:21  OPEN/BLOCKED  TestsPassed=[FAILURE]
11:24:46  OPEN/BLOCKED  TestsPassed=[FAILURE]      still blocked after 5.5 minutes
```

Three distinct merge paths were then tried on that same PR:

| Path | Outcome |
|---|---|
| `gh pr merge --auto --squash` | **never fires**, PR stays blocked |
| `gh pr merge --squash` | refused: `the base branch policy prohibits the merge` |
| `gh pr merge --squash --admin` | **merges**, overriding the failing check |

So the accurate model is:

> `bypass_actors` governs **direct pushes** and **explicit `--admin` overrides**.
> It does **not** loosen auto-merge. Auto-merge waits for required checks regardless
> of who armed it.

The four-second merges on spm/spm PRs #143, #145, #148 and #149 are fully explained by
there being no required check on `main` at all. They are not evidence of bypass
defeating a gate.

**Consequence for the rollout.** The goal and the constraint are not in tension, and
T11 removes the difficulty entirely. `bypass_actors` accepts **individual users**, so
the bypass list can name exactly the maintainers who should keep direct-push access and
simply leave SPMcentral out. No new team, no role changes, and the earlier worry about
SPMcentral being unavoidably included in every role or team is moot.

That is what the shipped JSON does. Both requirements hold simultaneously:

- **Maintainers keep direct push to `main`** because they are named bypass actors (T11).
- **The FieldTrip sync PR stays gated** because SPMcentral is not a bypass actor, so its
  `gh pr merge --auto --squash` waits for `Tests passed` like anyone else. T3 and T10
  prove a **non-bypassing** account's auto-merge works normally once the check goes
  green: PRs #6 and #11 were armed by an account with `current_user_can_bypass: "never"`
  and merged about 55 and 67 seconds later. SPMcentral needs no bypass at all.

**Nobody needs elevated repository permissions.** Bypass membership is not a repository
role. A maintainer on `write` stays on `write` and can still push to `main`; being named
in `bypass_actors` grants nothing anywhere else in the repository.

**The one capability you cannot trim.** T12 showed `bypass_mode: "pull_request"` does
not permit direct push, so every name on the list needs `"always"`, which also lets that
person `gh pr merge --admin` a red PR. Direct push and `--admin` override cannot be
separated. Every use of either is recorded in Rule Insights as `result: "bypass"`, so it
is auditable after the fact.

---

## 6. Importing into spm/spm

1. **Check the bypass list.** It holds the 11 active maintainers below. Starting point:
   everyone who both **(a)** has `write` or better on spm/spm and **(b)** committed to
   `main` in the 24 months to 2026-08-05, then narrowed by the SPM team to those still
   active on the project. `SPMcentral` is deliberately excluded.

   | `actor_id` | Login | Commits to `main`, 24 mo | Role |
   |---|---|---|---|
   | 62791783 | `Friston` | 82 | write |
   | 11646203 | `JohnAshburner` | 59 | admin |
   | 61868360 | `barnesgr123` | 39 | write |
   | 1307522 | `korbinian90` | 35 | admin |
   | 2145293 | `pzeidman` | 33 | write |
   | 19425611 | `johmedr` | 28 | maintain |
   | 60397421 | `AlexanderNA` | 16 | write |
   | 14015127 | `vlitvak` | 12 | write |
   | 14932031 | `tierneytim` | 12 | maintain |
   | 8765418 | `pranaysy` | 5 | write |
   | 118210848 | `Y-Bezs` | 4 | write |

   **Deliberately excluded**, each for a different reason:

   | Who | Why |
   |---|---|
   | `SPMcentral` (5950819) | the FieldTrip sync account. Omitting it is what gates the sync PR. See section 5. |
   | `gllmflndn`, `langestroop`, `balbasty`, `baskadym` | committed to `main` inside the window but are no longer active on the project. Removed on the SPM team's instruction. |
   | `arthurmitchell96`, `cgohil8`, `oliviakowalczyk` | hold `write` but no commits to `main` in 24 months. **They can push today and would lose it.** Add them if that is wrong. |
   | `VolkmarGlauche`, `ChristophePhillips`, `tejparr`, `RCTimms`, `NicoleLabrAvila`, `stephaniemellor`, `suvadeepmaiti` | `triage` only, so they cannot push to `main` regardless. A bypass entry would do nothing. |
   | `georgeoneill`, `WillForan`, `Remi-Gau`, `RaniaImanV` | `read` or not collaborators. Their commits arrived through PRs. |

   Note that these people keep their `write` role and can still contribute through pull
   requests exactly as before. Dropping someone from the bypass list only removes the
   ability to push straight to `main`.

   To add someone:

   ```
   gh api users/<login> --jq '.id'
   ```

   then append `{"actor_id": <id>, "actor_type": "User", "bypass_mode": "always"}`.
   `"always"` is required; `"pull_request"` does not permit direct push (T12).

2. Settings -> Rules -> Rulesets -> New ruleset -> Import a ruleset, and upload
   `main-required-checks.json`.
3. Confirm the bypass entries resolve to the expected people in the UI, and that
   **SPMcentral is not among them**.
4. Save with `enforcement: "active"`. Set `"disabled"` first if you want it parked,
   but note T8: parked rulesets produce no Rule Insights.

Points worth knowing before you flip it on:

- `strict_required_status_checks_policy` is **false**, so PRs are not forced to be up
  to date with `main` before merging. Setting it true would make every FieldTrip sync
  PR rebase whenever `main` moves, which on a daily sync means near-permanent churn.
- The context is pinned to `integration_id: 15368` (GitHub Actions). A check named
  `Tests passed` from any other app will not satisfy it.
- **`Tests passed` must be reported on every PR, or nothing will ever merge.** T5 is
  the proof. `matlab.yml` is currently the only `pull_request` workflow, and its
  aggregator uses `if: always()`, so it always reports. Keep it that way.
- The existing classic protection on `main` (`required_linear_history`, no force push,
  no deletion) is untouched by this ruleset and both apply together.
- Rulesets have no `enforce_admins` equivalent. With an empty bypass list the rule
  binds the org owners too.

---

## 7. Blocker: the CLA Assistant pushes straight to `main`

**This must be resolved before the ruleset goes active on spm/spm.** It is not a
theoretical risk, it is verified.

`.github/workflows/cla.yml` runs `contributor-assistant/github-action` with:

```yaml
path-to-signatures: 'signatures/version1/cla.json'
# branch should not be protected
branch: 'main'
```

The action commits each new signature and pushes it **directly to `main`** as
`github-actions[bot]`, using `GITHUB_TOKEN`. It is doing so today:

| Commit | Date | Author |
|---|---|---|
| `8e86b25f7` | 2026-07-23 | `github-actions[bot]` |
| `5d7659477` | 2026-05-27 | `github-actions[bot]` |
| `9c849392d` | 2026-02-24 | `github-actions[bot]` |

The workflow's own comment, `# branch should not be protected`, says exactly what the
problem is.

**T14** reproduced this on the fork with a workflow that commits a signature file and
pushes to `main` with `GITHUB_TOKEN`, the same way the real action does:

```
remote: error: GH013: Repository rule violations found for refs/heads/main.
remote: - Required status check "Tests passed" is expected.
 ! [remote rejected] HEAD -> main (push declined due to repository rule violations)
RESULT: bot push REJECTED
```

So with the ruleset active, **every new external contributor's CLA signature fails to
record.** Contributor onboarding breaks.

### Three ways out

1. **Move the signatures off the default branch.** Change `branch: 'main'` to a branch
   like `cla-signatures` in `cla.yml`. The ruleset targets `~DEFAULT_BRANCH` only, so a
   non-default branch is untouched. One line, no bypass grant, nothing widened. The
   branch may need creating first. **Recommended.**

2. **Store the signatures in a separate repository.** The action supports
   `remote-organization-name` / `remote-repository-name` plus a PAT, and the comment in
   `cla.yml` already anticipates it (`this can be 'read' if the signatures are in remote
   repository`). Cleanest long term, most setup.

3. **Add GitHub Actions as an `Integration` bypass actor**
   (`{"actor_id": 15368, "actor_type": "Integration", "bypass_mode": "always"}`).
   Zero workflow change. Two caveats: it lets **any** workflow using `GITHUB_TOKEN` push
   straight to `main`, which is wider than the CLA bot alone; and it **could not be
   verified here**. The fork is a personal repository, and the API refused the actor
   with `Actor GitHub Actions integration must be part of the ruleset source or owner
   organization`. It should be valid on spm/spm, which is org-owned, but that is an
   expectation and not a tested result.

Whichever route is taken, re-run T14's equivalent on spm/spm before trusting it: have a
contributor sign, or trigger the CLA workflow, and confirm the signature commit lands.

## 8. Fork state after testing

Restored or left as follows:

- Classic branch protection on korbinian90/spm `main` was **deleted** for testing. It
  had exactly one setting worth restoring: `required_pull_request_reviews` with
  `required_approving_review_count: 1`, `dismiss_stale_reviews: false`,
  `require_code_owner_reviews: false`, `require_last_push_approval: false`. Everything
  else was already off. Restore with:

  ```
  gh api -X PUT repos/korbinian90/spm/branches/main/protection --input - <<'EOF'
  {"required_status_checks":null,"enforce_admins":false,
   "required_pull_request_reviews":{"dismiss_stale_reviews":false,
   "require_code_owner_reviews":false,"required_approving_review_count":1},
   "restrictions":null}
  EOF
  ```

- The `Tests` workflow (`matlab.yml`) was **already** `disabled_manually` on the fork
  before this work began and was left that way.
- The stub workflow remains on the fork so the rig stays usable. It is test
  scaffolding and must **not** be ported to spm/spm.
- The fork ruleset (id 20451642) was set to `enforcement: "disabled"` so the fork is
  not left with a permanently unsatisfiable required check. Re-arm with:

  ```
  gh api -X PUT repos/korbinian90/spm/rulesets/20451642 --input - <<< '{"enforcement":"active"}'
  ```
