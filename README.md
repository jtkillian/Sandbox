Sandbox — MATLAB project template with CI

WHAT'S HERE
  • src/           Application/library code (created automatically if missing)
  • tests/         matlab.unittest tests (created automatically if missing)
  • run_ci.m       CI entrypoint (writes JUnit + Cobertura reports)
  • ci/            CI notes artifacts written by GitHub Actions

QUICK START (LOCAL)
  1) Open this folder in MATLAB or VS Code.
  2) Put .m files in src/ and tests in tests/ (function- or class-based).
  3) From MATLAB Command Window:
        >> run_ci
     or from VS Code:
        • Run task: "ci: run_ci"

TESTS
  • Use matlab.unittest:
      import matlab.unittest.TestCase
      classdef test_example < TestCase
          methods (Test)
              function demo(t)
                  t.verifyEqual(1+1, 2);
              end
          end
      end
  • Place tests under tests/ (subfolders OK). CI finds them automatically.

CI PIPELINE (GITHUB ACTIONS)
  • Runs run_ci.m to generate:
      - test-results/results.xml  (JUnit)
      - code-coverage/coverage.xml (Cobertura)
  • Posts CI notes to the PR; optionally generates one-time AI summary.
  • On failures, drafts a targeted fix prompt for @copilot (AI when quota allows,
    otherwise deterministic fallback).

NOTES
  • On a blank repo (no tests yet), CI stays green and writes empty reports.
  • Coverage thresholds are enforced in the workflow, not in run_ci.m.
