{
  description = "Prebuilt Ladybird browser (unofficial, macOS arm64)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs { inherit system; };

      # --- Release pin. ---
      # `releaseTag` is the release tag (build-YYYY-MM-DD), `version` its date
      # part, and `hash` the SRI sha256 of that release's Ladybird-macos-arm64.zip.
      #
      # The release job rewrites all three and commits them, so consumers only
      # need `nix flake update ladybird-builds`. Bump by hand if that step failed:
      #   nix store prefetch-file --json --hash-type sha256 <release-zip-url>
      releaseTag = "build-2026-10-21";
      version = "2026-10-21";
      hash = "sha256-4tCf9yuWky1lYK9bPf4gUpxScaLp2+9upq25S1i6nYA=";
      # ------------------------------------------------------------------

      ladybird = pkgs.stdenvNoCC.mkDerivation {
        pname = "ladybird";
        inherit version;

        # fetchurl, not fetchzip: the CI release step hashes the zip itself
        # (`openssl dgst -sha256 -binary | base64`), which needs no Nix on the
        # runner. The bundle is unpacked by the default unpackPhase below.
        src = pkgs.fetchurl {
          url = "https://github.com/remusa/ladybird-builds/releases/download/${releaseTag}/Ladybird-macos-arm64.zip";
          inherit hash;
        };

        nativeBuildInputs = [ pkgs.unzip ];

        # The zip holds a single top-level Ladybird.app/, so pin sourceRoot to the
        # unpack directory: the default would cd INTO the bundle and then
        # `cp -R Ladybird.app` finds nothing.
        sourceRoot = ".";

        # A release bundle: nothing to configure, nothing to build.
        dontConfigure = true;
        dontBuild = true;

        # nixpkgs convention for a .app is $out/Applications, which is what
        # mac-app-util and nix-darwin's system-applications look for.
        installPhase = ''
          runHook preInstall
          mkdir -p $out/Applications
          cp -R Ladybird.app $out/Applications/
          runHook postInstall
        '';

        meta = with pkgs.lib; {
          description = "Unofficial build of the Ladybird browser";
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
