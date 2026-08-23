# AGENTS.md - Instructions for Automated Agents

## Commit Guidelines

- Always use [conventional commits](https://www.conventionalcommits.org/): `<type>(<scope>): <description>`
- Types: `feat`, `fix`, `docs`, `chore`, `ci`, `refactor`, `style`, `test`, `perf`, `build`, `revert`
- Never use `--no-verify` or bypass pre-commit hooks unless explicitly asked by the user.

## Linting & Formatting

Run `mise run lint` to check all files, or `mise run fmt` to auto-fix.

Tools are managed via mise — run `mise install` to set up the dev environment.

| File type | Linter       | Formatter |
|-----------|--------------|-----------|
| YAML      | actionlint   | —         |
| Nix       | nixfmt       | nixfmt    |
| Ruby      | rubocop      | rubocop   |
| Markdown  | markdownlint | —         |
| Shell     | shfmt        | shfmt     |

## Project Structure

- `.github/workflows/build.yml` — weekly macOS arm64 nightly build CI
- `flake.nix` — Nix flake for prebuilt binary distribution
- `ladybird-nightly.rb` — Homebrew cask formula
- `mise.toml` — tool versions and task runner
