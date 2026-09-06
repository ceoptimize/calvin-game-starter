---
name: route
description: >-
  Manual two-model implementation loop. Fable 5 plans and reviews; Codex
  (OpenAI) implements and fixes, sandboxed to the workspace. Trigger only when
  the user explicitly types /route, says "route this", or asks for the
  Fable-plus-Codex loop.
---

# Route: Fable 5 directs Codex

You are Fable 5 and own planning, review, and final approval. Codex owns implementation and fixes. Codex runs SANDBOXED: `workspace-write` for implementation, `read-only` for review. Never use `--dangerously-bypass-approvals-and-sandbox` or `danger-full-access`. Never commit, push, or deploy without the user's explicit approval in this conversation.

## Workflow

1. Inspect the repository, AGENTS.md/CLAUDE.md instructions, git status, relevant code, and tests. Preserve unrelated user changes.
2. Restate the requested outcome and write a concrete implementation plan to `.route/PLAN.md`. Create `.route/` if needed. Include:
   - scope and acceptance criteria;
   - files likely to change;
   - verification commands;
   - compatibility and rollback considerations.
3. Ask Codex to implement the plan:
   codex exec --model gpt-5.6-sol -s workspace-write -c model_reasoning_effort=high "Read .route/PLAN.md and the repository instructions. Implement only the approved scope. Preserve unrelated changes. Run the smallest relevant verification and report every file changed."
4. Review the result yourself:
   - inspect the complete diff;
   - run relevant tests, linting, or type checks;
   - check correctness, edge cases, security, regressions, and scope discipline.
5. Run a separate read-only Codex review:
   codex exec --model gpt-6-astra -s read-only -c model_reasoning_effort=high "Review the uncommitted changes in this repository adversarially for correctness, regressions, security, missing tests, and unnecessary scope. Return findings only; do not modify files."
6. If there are actionable findings, write them precisely to `.route/FIXES.md` and dispatch a fix pass:
   codex exec --model gpt-5.6-sol -s workspace-write -c model_reasoning_effort=high "Read .route/PLAN.md and .route/FIXES.md. Fix only the documented findings, preserve unrelated changes, and rerun the relevant verification."
7. Repeat review and fixes until no concrete findings remain. There is no fixed pass cap; if the loop stops converging, report the remaining findings rather than churning.
8. Once the diff is reviewed and verification passes, STOP and report:
   - what was planned;
   - what Codex changed;
   - review findings and fixes;
   - verification results;
   - a proposed commit message.
   Commit only if the user approves; never push or deploy autonomously.

## Operating notes

- Models are split by token shape, not by project: implementation and fix passes write a lot of code, so they run `gpt-5.6-sol`; the adversarial review reads a lot and writes little, so it runs `gpt-6-astra` (needs Codex CLI 0.153 or newer). To change a model, edit the `--model` flag on that step.
- Always inspect the full diff and run relevant verification before treating work as done.
- The sandbox confines Codex writes to the workspace; the diff review is the quality gate.
- Do not discard or overwrite unrelated existing changes.
- Stay within the requested outcome; note material scope expansions in the report.
- This workflow runs only when explicitly invoked.
- Add `.route/` to the project's .gitignore if it isn't already there.
