# Copilot instructions

## Repository shape
- MATLAB-focused template: custom logic belongs in `src/*.m`; `tests/*.m` hosts `matlab.unittest` suites.
- `run_ci.m` is the CI entrypoint. It bootstraps `src/` + `tests/`, adds them to the MATLAB path, and guarantees `test-results/` + `code-coverage/` exist.
- Empty folders retain `.gitkeep` files; keep them so first-time clones stay CI-safe.

## Local workflows
- Default verification: run the VS Code task **ci: run_ci** (wraps `matlab -batch "cd('${workspaceFolder}'); run_ci"`).
- Quick iteration: use **tests: matlab** for `runtests` only, or **lint: matlab (checkcode)** to lint `src/`.
- Headless CLI alternative:
  - `matlab -batch "cd('<repo-root>'); run_ci"` for full reports.
  - `matlab -batch "cd('<repo-root>'); runtests"` when you do not need coverage output.

## Testing expectations
- Suites are discovered via `TestSuite.fromFolder('tests', 'IncludingSubfolders', true)`. Organize tests accordingly (class-based or function-based is fine).
- Tests must be deterministic—seed RNGs (`rng default`) and avoid interactive graphics/UI calls.
- Coverage is collected for everything under `src/` (including subfolders). Keep public APIs in `src/` so coverage accounting works.
- CI enforces a minimum line coverage of 60% (`matlab-ci.yml` → `MIN_COVERAGE`). Add or update tests when touching production code.

## CI behaviors to respect
- Workflow `.github/workflows/matlab-ci.yml` runs `run_ci`, parses JUnit + Cobertura XML, and posts `ci/CI-NOTES.md` comments summarizing metrics.
- When coverage or tests fail, the workflow may request fixes with an AI plan; expect to follow up until coverage ≥ 60 and all suites pass.
- Agent PRs must target approved bases (`bot/main`, `bots/main`, `dev`, `main`) and use a head branch prefixed with `bot/copilot-` or `bot/codex-` (see `REQUIRED_HEAD_PREFIXES`).

## Implementation hints
- New functionality should live in namespaced packages (subfolders inside `src`); expose entry points with function files, and mirror structure under `tests` for coverage clarity.
- Prefer returning data instead of printing inside functions; let tests assert on outputs via `verifyEqual`, `verifyTrue`, etc.
- Keep helper scripts idempotent—`run_ci` may execute multiple times per pipeline run, so avoid persisting temporary files outside `test-results/` or `code-coverage/`.
- If you need additional CI artifacts, drop them under `ci/` so existing upload steps collect them automatically.
