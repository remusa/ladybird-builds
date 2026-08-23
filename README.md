# ladybird-builds

Unofficial CI that builds [Ladybird](https://ladybird.org) from source for
macOS arm64 and publishes nightly `.app` bundles as GitHub Releases.

This is **not** an official Ladybird distribution. Ladybird is pre-alpha
software; expect breakage, and expect this pipeline to need occasional
babysitting as upstream's build system changes.

## What's here

- `.github/workflows/build.yml` — scheduled (weekly) GH Actions workflow.
  Builds on a `macos-15` (Apple Silicon) hosted runner, zips the resulting
  `Ladybird.app`, and publishes it as a GitHub Release tagged
  `nightly-YYYY-MM-DD`.
- `flake.nix` — a Nix flake that fetches the *prebuilt* binary from this
  repo's latest release (does not build from source under Nix — see below
  for why).

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

You'll need to bump `version` and `sha256` in `flake.nix` after each
release you want to pin to — get the hash with:

```
nix-prefetch-url --unpack \
  https://github.com/YOUR_GH_USERNAME/ladybird-builds/releases/download/nightly-YYYY-MM-DD/Ladybird-macos-arm64.zip
```

**Manual download:** grab the zip from Releases, unzip, drag to
`/Applications`.

## Gatekeeper / quarantine

These builds are not code-signed or notarized (no Apple Developer account
in this pipeline). macOS will refuse to open the app normally. Either:

```
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
- Consider pruning old nightly releases periodically; they're not meant to
  be a permanent archive.
