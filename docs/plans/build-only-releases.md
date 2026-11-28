# Plan: build only upstream releases (ladybird-builds)

Status: implemented — PR #12 (feat/build-only-releases). Authored 2026-11-27.

## Question

Should `remusa/ladybird-builds` stop building `LadybirdBrowser/ladybird` `master`
nightly and instead build only upstream's tagged releases (the alphas now
published at https://github.com/LadybirdBrowser/ladybird/releases)?

## Scout findings

- Upstream now publishes real releases: tags `2026.48.0`, `2026.47.8`, `2026.47.7`,
  cadence ~3/week (and an initial "Ladybird alpha" release). Each is a curated,
  tested snapshot with release notes. Latest: `2026.48.0` published 2026-11-26.
- Current CI builds `LADYBIRD_REF: master` on a nightly cron (`0 2 * * *`),
  ~1.5h/run × 3 platforms = ~4.5h/night ≈ 31h/week, with re-dispatches for
  upstream churn (GC captures mid-migration, `ak` crate deprecation, etc.).
- Releases are more stable build targets than mid-flight `master`; the recent
  red runs were all caused by checking out a half-migrated tree.
- Consumers:
  - `homelab` flake pins `releaseTag`/`version`/`hash` in `flake.nix` and is
    auto-updated by the publish job's pin commit.
  - `remusa/homebrew-tap` cask `ladybird-nightly.rb` uses `version :latest` and
    `releases/latest/download/Ladybird-macos-arm64.zip`, so it only needs the
    asset name stable and a newest release to exist — tag scheme does not matter.
- macOS auto-update + Linux package manager are upstream's own delivery; our
  consumers only update on `nix flake update` (manual), so daily vs weekly
  freshness barely matters to them.

## Recommendation

**Yes — switch to building upstream releases.** Rationale:

1. Fewer broken builds: release tags are stable points; we avoid the
   half-migrated-tree failures seen on `master`.
2. ~60% less CI: ~3 releases/week instead of 7 nightly runs.
3. Meaningful versions: consumers see upstream version numbers (2026.48.0)
   instead of build dates.
4. Cask unaffected (uses `latest`).

Trade-off accepted: we stop catching upstream regressions a day early. The
failure-notify + manual `workflow_dispatch` (with ref pin) still cover that.

## Proposed design

### Trigger / polling
Keep a daily cron (`0 2 * * *`) as a poll, plus `workflow_dispatch`. Add a
`resolve` job that:
- checks out `self`,
- reads the currently pinned `releaseTag` from `flake.nix`,
- queries `gh api repos/LadybirdBrowser/ladybird/releases/latest` for the
  latest tag,
- outputs `should_build` (true iff upstream tag != pinned tag) and `upstream_tag`.
Build/publish jobs run only when `should_build == 'true'`. A no-op poll stays
green.

Manual dispatch gains an optional `ref` input (default = latest upstream
release) for pin-escape-hatch builds.

### Source checkout
Replace `LADYBIRD_REF: master` with the resolved upstream tag. `fetch-depth: 0`
already allows tag checkout.

### Release identity
Use the upstream version as our release tag (e.g. `2026.48.0`) instead of
`build-YYYY-MM-DD`. Update:
- publish tag_name/name to the upstream version,
- flake pin `releaseTag`/`version` to the upstream version,
- download URL pattern `releases/download/${releaseTag}/...` (unchanged shape).
- guard: compare upstream version (not date+commit). Keep refuse-to-overwrite.

### Pruning
`RELEASE_RETENTION` keeps N newest releases; sort by version instead of the
date regex. Note: lexicographic sort is slightly wrong for patch >= 10
(`2026.47.10` < `2026.47.8`); acceptable, or parse components.

### Outputs
Replace `date` output with `version` (upstream tag) throughout build-macos /
build-linux / publish. `sha` (source commit) stays for the release name.

## Migration / one-time steps
1. First run will publish a release under the new tag scheme and push a pin
   commit rewriting `flake.nix` (`releaseTag = "2026.48.0"` etc.). Consumers
   run `nix flake update ladybird-builds`.
2. Update `AGENTS.md`/skill references from `build-YYYY-MM-DD` to the new
   scheme (docs only).
3. Keep `RELEASE_RETENTION` semantics; old `build-*` releases will age out.

## Risks / open questions
- Some upstream releases may still be broken to build (less likely than
  master, but possible). The notify issue + manual dispatch + ref pin cover it.
- If upstream publishes a release and then re-tags (rare), our guard refuses
  to overwrite — matches current behavior.
- `make_latest: true` keeps `releases/latest` pointing at newest; cask fine.
- Asset names must remain `Ladybird-macos-arm64.zip`,
  `Ladybird-linux-arm64.tar.gz`, `Ladybird-linux-x86_64.tar.gz`.

## Out of scope
- Switching Linux consumers to upstream's new AppImage.
- macOS notarization/signing.
- Changing the cask (already `latest`-based).

## Files to touch (in ladybird-builds repo)
- `.github/workflows/build.yml` (trigger, resolve job, ref, tag scheme, guard,
  prune, pin step)
- `flake.nix` (first run rewrites; no manual edit needed)
- `AGENTS.md`, skill docs (terminology)
