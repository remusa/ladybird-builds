# ladybird-builds

Unofficial CI that builds [Ladybird](https://ladybird.org) from source for
macOS arm64 and publishes `.app` bundles as GitHub Releases.

This is **not** an official Ladybird distribution. Ladybird is pre-alpha
software; expect breakage, and expect this pipeline to need occasional
babysitting as upstream's build system changes.

## What's here

- `.github/workflows/build.yml` — twice-weekly GH Actions workflow (Sundays
  and Wednesdays 02:00 UTC = 10:00 local, plus `workflow_dispatch`). It builds
  whatever `LadybirdBrowser/ladybird@master` is that day, so nothing needs
  bumping by hand; a failed run opens an issue (GitHub's
  failed-scheduled-workflow email is the backstop). Releases older than the
  newest 20 are pruned automatically after each successful build.
  Builds on a `macos-15` (Apple Silicon) hosted runner: `cmake --install`
  lays the bundle down, upstream's `Meta/package-macos-app-bundle.py`
  packages it (deploys Qt with `macdeployqt`, drops absolute rpaths,
  re-signs, verifies nothing points outside the bundle), and the resulting
  tarball is repacked into `Ladybird-macos-arm64.zip` and published as a
  GitHub Release tagged `build-YYYY-MM-DD`. The build needs Qt 6.10+
  (Homebrew `qt`); the workflow selects the newest Xcode preinstalled on
  the runner itself.
- `flake.nix` — a Nix flake that fetches the *prebuilt* binary from this
  repo's latest release (does not build from source under Nix — see below
  for why).

## Which Ladybird a machine runs

The workflow tracks upstream `master`, but nothing downstream floats with it.
Each successful run pins **this** repo's `flake.nix` to the release it just
published (`version` + the zip's sha256), so consumers stay on a known-good
build until they ask for a new one:

```sh
nix flake update ladybird-builds   # then darwin-rebuild switch
```

Because the release job only pins after a green build, a broken upstream week
never reaches anyone: the flake keeps pointing at the last release that built.

To hold a specific build, pin the input to the commit that carries it, or stop
updating. To stopgap a run of broken upstream weeks, set `LADYBIRD_REF` in the
workflow to the last known-good SHA (full 40 characters — `actions/checkout`
treats a short SHA as a branch/tag name and fails) and dispatch manually.

## Rebuilding after upstream churn

Upstream has broken this pipeline four times: a required Xcode SDK constant,
Qt becoming a mandatory dependency, and a vcpkg mirror flake. The first two are
handled in the workflow already (it selects the newest preinstalled Xcode, and
installs Homebrew `qt`); if a new one appears, the failure issue links the run
and the log names the missing prerequisite. Compare against
`Documentation/BuildInstructionsLadybird.md` upstream.

## Consuming a build

**Homebrew:** see the cask in the separate tap repo, which points at this
repo's `releases/latest`.

**nix-darwin:** add this repo as a flake input and pull in
`darwinModules.default`:

```nix
{
  inputs.ladybird-builds.url = "github:YOUR_GH_USERNAME/ladybird-builds";

  outputs = { self, nixpkgs, ladybird-builds, ... }: {
    darwinConfigurations."your-host" = nix-darwin.lib.darwinSystem {
      modules = [
        ladybird-builds.darwinModules.default
        # ...your other modules
      ];
    };
  };
}
```

`flake.nix` pins one release (`version` = tag date, `hash` = the SRI sha256
of the zip) and the release job rewrites both and commits them itself, so
consumers only need:

```sh
nix flake update ladybird-builds
```

If that commit step ever fails, bump by hand with the hash it would have
used — note this is the hash of the **zip**, not of its contents (the flake
uses `fetchurl`, not `fetchzip`):

```sh
nix store prefetch-file --json --hash-type sha256 \
  https://github.com/YOUR_GH_USERNAME/ladybird-builds/releases/download/build-YYYY-MM-DD/Ladybird-macos-arm64.zip
```

Only one release per UTC day can exist: the tag is the build date and the
workflow refuses to overwrite an existing release's asset, because replacing
bytes under a tag would break every pinned consumer.

**Manual download:** grab the zip from Releases, unzip, drag to
`/Applications`.

## Gatekeeper / quarantine

These builds are not code-signed or notarized (no Apple Developer account
in this pipeline). macOS will refuse to open the app normally. Either:

```sh
xattr -d com.apple.quarantine /Applications/Ladybird.app
```

or right-click → Open the first time and confirm through the dialog.

## Why the Nix flake fetches a binary instead of building from source

Ladybird's build uses vcpkg to fetch and compile third-party dependencies
at build time. That model conflicts with Nix's sandboxed, network-isolated
build environment (every fetch would need to be its own pinned
fixed-output derivation, which is impractical to maintain against a
dependency manifest that changes as often as upstream's does right now).
Fetching this repo's already-built binary sidesteps that entirely — Nix
just needs a stable URL and a hash.

## Maintenance notes

- If `Meta/ladybird.py build` starts failing, check
  `Documentation/BuildInstructionsLadybird.md` in the Ladybird source tree
  for changes to required dependencies or build flags.
- The `actions/cache` key is tied to `vcpkg.json` / `vcpkg-configuration.json`
  hashes, so cache invalidates automatically when upstream's dependency
  manifest changes.
- Old releases are pruned automatically (the newest 20 are kept); they are not
  meant to be a permanent archive.
