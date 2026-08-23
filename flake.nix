{
  description = "Prebuilt Ladybird browser (unofficial nightly, macOS arm64)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs { inherit system; };

      # --- Bump these two on every nightly release. ---
      # Get the sha256 with:
      #   nix-prefetch-url --unpack <release-zip-url>
      version = "2026-08-22"; # matches the release tag date
      sha256 = "0000000000000000000000000000000000000000000000000000"; # REPLACE ME
      # --------------------------------------------------

      ladybird = pkgs.stdenvNoCC.mkDerivation {
        pname = "ladybird";
        inherit version;

        src = pkgs.fetchurl {
          url = "https://github.com/YOUR_GH_USERNAME/ladybird-builds/releases/download/nightly-${version}/Ladybird-macos-arm64.zip";
          inherit sha256;
        };

        nativeBuildInputs = [ pkgs.unzip ];

        sourceRoot = ".";

        installPhase = ''
          mkdir -p "$out/Applications"
          cp -r "Ladybird.app" "$out/Applications/"
        '';

        meta = with pkgs.lib; {
          description = "Unofficial nightly build of the Ladybird browser";
          homepage = "https://ladybird.org";
          platforms = [ "aarch64-darwin" ];
        };
      };
    in
    {
      packages.${system}.default = ladybird;
      packages.${system}.ladybird = ladybird;

      # Import this into your nix-darwin config's `imports` list, e.g.:
      #   imports = [ inputs.ladybird-builds.darwinModules.default ];
      #   environment.systemPackages = [ pkgs.ladybird ]; -- not needed, module does it
      darwinModules.default = { pkgs, ... }: {
        environment.systemPackages = [ ladybird ];
      };
    };
}
