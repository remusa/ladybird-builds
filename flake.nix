{
  description = "Prebuilt Ladybird browser (unofficial nightly, macOS arm64)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs { inherit system; };

      # --- Bump these two on every nightly release. ---
      # version matches the release tag date (nightly-YYYY-MM-DD).
      # Get the sha256 with:
      #   nix-prefetch-url --unpack https://github.com/remusa/ladybird-builds/releases/download/nightly-YYYY-MM-DD/Ladybird-macos-arm64.zip
      version = "2026-10-11"; # matches the release tag date
      sha256 = "17hbs4gqvc9xjghl1qsrhy37ac98ng2qx76cmv4qbvkgbc3413rp"; # see above for bump
      # --------------------------------------------------

      ladybird = pkgs.stdenvNoCC.mkDerivation {
        pname = "ladybird";
        inherit version;

        # fetchzip, not fetchurl: the documented bump command prefetches with
        # `nix-prefetch-url --unpack`, which hashes the *contents*, not the zip.

        src = pkgs.fetchzip {
          url = "https://github.com/remusa/ladybird-builds/releases/download/nightly-${version}/Ladybird-macos-arm64.zip";
          inherit sha256;
        };

        # fetchzip has already extracted the zip by the time this derivation
        # runs, and the zip contains *only* Ladybird.app, so the store path
        # holds a bare `Contents/` at its root. Skip unpackPhase and rebuild
        # the app path from it.
        unpackPhase = "true";

        installPhase = ''
          runHook preInstall
          mkdir -p "$out/Applications/Ladybird.app"
          cp -r "$src/Contents" "$out/Applications/Ladybird.app/Contents"
          chmod -R u+w "$out/Applications"
          runHook postInstall
        '';

        meta = with pkgs.lib; {
          description = "Unofficial nightly build of the Ladybird browser";
          homepage = "https://ladybird.org";
          platforms = [ "aarch64-darwin" ];
        };
      };
    in
    {
      # One nested attrset: two separate `packages.${system}.<name>` lines
      # would be dynamic attributes defined twice, which Nix rejects.
      packages.${system} = {
        default = ladybird;
        ladybird = ladybird;
      };

      # Import this into your nix-darwin config's `imports` list, e.g.:
      #   imports = [ inputs.ladybird-builds.darwinModules.default ];
      #   environment.systemPackages = [ pkgs.ladybird ]; -- not needed, module does it
      darwinModules.default = { pkgs, ... }: {
        environment.systemPackages = [ ladybird ];
      };
    };
}
