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
| Markdown  | markdownlint | —         |
| Shell     | shfmt        | shfmt     |

## Project Structure

- `.github/workflows/build.yml` — dispatch-only macOS arm64 nightly build CI
- `flake.nix` — Nix flake for prebuilt binary distribution
- the Homebrew cask lives in `remusa/homebrew-tap` (`Casks/ladybird-nightly.rb`), not here
- `mise.toml` — tool versions and task runner

## Cross-Repo Conventions

These apply across all repositories (nix-config, nixos-config, homebrew-tap, etc.):

- **Never remove comments** from config files (Nix, YAML, Ruby, etc.)
- **Preserve all comments** when editing — if unsure, keep it
- **Never edit configs without asking** — confirm before modifying any config file
- **Check OpenCode session history** before tackling a problem — similar work may have been done
  - Sessions DB: `~/.local/share/opencode/opencode.db` (SQLite)
