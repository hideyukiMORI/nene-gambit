# NeNe Gambit — Agent Guide

Short English entry point. The authoritative handbook is [CLAUDE.md](CLAUDE.md) (Japanese);
the normative documents live in [docs/](docs/).

## Project identity

- Product: NeNe Gambit — a Swift terminal screensaver where two hand-written chess AIs play each other forever
- Language / UI: Swift 6 / terminal (ANSI escapes, no ncurses)
- Package: `NeNeGambit` (SwiftPM, Swift 6.4.1 pinned in `.swift-version`, zero external dependencies)
- Governing principle: **one meaning, one canonical implementation path, enforced by machines**

## Required reading before changing production code

1. `docs/ARCHITECTURE_CONSTITUTION.md`
2. `docs/PROJECT_LAYOUT.md`
3. `docs/CODING_RULES.md`
4. `docs/QUALITY_GATES.md`
5. `docs/DEVELOPMENT_WORKFLOW.md`
6. `docs/COMMIT_CONVENTIONS.md`
7. `docs/GLOSSARY.md`

Then the active issue, the relevant accepted ADRs, and any active waivers.

## Agent rules

- Do not invent a second implementation path because it is locally convenient.
- Do not weaken a gate to make a change pass. Fix the code instead.
- Do not mark a rule `active` in `docs/QUALITY_GATES.md` before its enforcement exists.
- Do not read the current time, randomness, locale, or environment outside the `nene-gambit` executable target (the composition root).
- Do not write `default:`, `@unknown default`, `case _:`, or `case let x:` in a `switch`; they disable exhaustiveness checking.
- Do not add a SwiftPM target without `.treatAllWarnings(as: .error)` and `ExistentialAny`; the manifest beats command-line flags.
- Do not add external packages, and never a chess engine or chess library (owner's decision).
- Do not fill in the owner's open questions (Q4–Q10 in the work order) yourself; ask.
- Do not add suppressions, lint baselines, or tool exclusions without an active waiver (or at all, where the language forbids them).
- Do not claim a command passed unless it was actually executed.
- Prefer the smallest change that fully follows the canonical path.

## The only definition of done

```bash
make bootstrap   # once after clone
make check
```

Local and CI run exactly this. Use narrow checks while iterating; run the full gate before
moving the PR from Draft to Ready.

## Required completion report

Issue and rule IDs, files and behavior changed, verification commands and results,
documentation or schema changes, active waiver IDs (or `none`), remaining risks.

Investigation-only requests do not authorize editing, committing, pushing, or opening PRs.
