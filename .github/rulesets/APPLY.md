# Applying the rulesets to spm/spm

Run these from a checkout of spm/spm, with `gh` authenticated as an org owner.
Every command below was rehearsed on the korbinian90/spm fork first; see
[`RULESET-TEST-LOG.md`](RULESET-TEST-LOG.md).

## Preconditions

Already satisfied as of 2026-08-20, listed so they can be re-checked if this sits
unapplied for a while:

- `cla.yml` points at `branch: 'cla-signatures'` and `signatures/version1/cla.json`
  is gone from `main` (spm/spm#155). Without this the CLA Assistant breaks, see
  section 7 of the log.
- The `cla-signatures` branch exists and holds the signature file.
- `Tests passed` is published on pull requests by GitHub Actions (app id 15368).
- spm/spm has no rulesets yet.

## 1. Protect the signature branch

```bash
gh api -X POST repos/spm/spm/rulesets --input .github/rulesets/cla-signatures-protection.json
```

Blocks force pushes and deletion on `cla-signatures`. Ordinary appends still work, so
the CLA Assistant is unaffected (T16).

## 2. Require the test check on main

```bash
gh api -X POST repos/spm/spm/rulesets --input .github/rulesets/main-required-checks.json
```

Requires `Tests passed` on the default branch. The 11 named maintainers keep direct
push; everyone and everything else goes through a green pull request.

Both files can also be uploaded through Settings -> Rules -> Rulesets -> New ruleset ->
Import a ruleset.

## 3. Verify

```bash
# both rulesets present and active
gh api repos/spm/spm/rulesets --jq '.[]|"\(.id)  \(.name)  \(.enforcement)"'

# bypass list resolves to the intended people
gh api repos/spm/spm/rulesets --jq '.[]|select(.name=="main-required-checks").bypass_actors[].actor_id' \
  | while read id; do gh api "user/$id" --jq '.login'; done
```

Expected logins: Friston, JohnAshburner, barnesgr123, korbinian90, pzeidman, johmedr,
AlexanderNA, vlitvak, tierneytim, pranaysy, Y-Bezs.

Then confirm behaviour on a real pull request: it should sit at `BLOCKED` until
`Tests passed` reports success. `current_user_can_bypass` on the ruleset is the
reliable indicator of whether a given account can push directly. Do **not** use
`git push --dry-run`, it reports success against a ref it cannot actually update (T13).

## 4. Afterwards

- **Re-enable `sync-fieldtrip.yml`**, currently `disabled_manually`. It was switched off
  because the sync pull requests were merging unchecked, which is what these rulesets
  fix. This is the end-to-end test: the sync PR should hold until `Tests passed` goes
  green, then squash-merge itself.
- **Open pull requests need a CI run** before they can merge. Anything not updated since
  the aggregator job landed has no `Tests passed` check on its head commit and will show
  as blocked until someone pushes to it or re-runs the workflow. Worth warning the
  authors of the active ones.
- The first CLA signature after this should land on `cla-signatures`. Worth checking
  once.

## Rolling back

```bash
# park a ruleset without deleting it (no effect, but also no Rule Insights)
gh api -X PUT repos/spm/spm/rulesets/<id> --input - <<< '{"enforcement":"disabled"}'

# remove entirely
gh api -X DELETE repos/spm/spm/rulesets/<id>
```

## Maintaining the bypass list

Membership is 11 explicit user ids. Adding or removing someone means editing the
ruleset. To add a person:

```bash
gh api "user/<login>" --jq '.id'    # or: gh api users/<login> --jq '.id'
```

then add `{"actor_id": <id>, "actor_type": "User", "bypass_mode": "always"}`.
`"always"` is required; `"pull_request"` does not permit direct push (T12).

Note for whoever maintains this later: a team as bypass actor would move this into org
settings and avoid ruleset edits per personnel change. It was considered and the named
list was chosen deliberately.
