---
name: test-review
description: Review test coverage and test quality for meaningful behavior, missing scenarios, redundant cases, trustworthy assertions, and lasting maintenance value. Use when asked to audit tests or review a change's test coverage, across languages and frameworks.
---

# Test review

Review the requested scope; otherwise use the current diff and related tests. Read requirements, implementation, shared setup, and project test conventions. Derive expected behavior from contracts; identify uncertain assumptions. Review only unless changes are requested.

## Requirements

Use these stable numeric IDs in findings. Apply framework-specific guidance only where relevant.

- **01. Valuable behavior.** Each case protects a contract or realistic regression. Identify the plausible bug it catches. Executing lines, rechecking framework guarantees, or increasing coverage percentages alone does not justify a test.
- **02. Relevant coverage.** Map important behavior to assertions. Check success, failure, boundaries, and side effects where the contract or risk warrants them. Recommend concrete missing scenarios without exhaustive permutations or speculative edge cases.
- **03. Distinct protection.** Flag cases that catch the same bugs. Name the case preserving coverage before recommending deletion or consolidation. Similar cases at different layers or boundaries may protect different failures.
- **04. Effective assertions.** Assertions must detect plausible wrong results and precisely check the claimed outcome. Flag tautologies, expectations derived from the same production logic, broad exception checks, and checks proving only setup or mocked values. Multiple assertions describing one outcome are fine.
- **05. Real subject.** Exercise the actual behavior. Flag stubbing or replacing the subject's own behavior. Dependency doubles are appropriate at clear boundaries with realistic contracts; they must not supply the result the test claims to verify.
- **06. Lasting value.** Cases should remain useful while the behavior is supported. Flag PR-specific transitional checks, temporary scaffolding, and implementation-presence checks without lasting contracts. Regressions discovered during a PR can still deserve permanent coverage.
- **07. Credible scenarios.** Setup must reach the intended path. Negative cases need an opportunity for the forbidden outcome; empty data, unrelated validation failures, or earlier guards must not cause accidental passes. Verify promised absence of side effects.
- **08. Appropriate layer.** Use the simplest layer that exposes the failure. Check integration gaps hidden by doubles, including persistence and boundary wiring. Keep broader tests protecting these contracts without duplicating every lower-level permutation.
- **09. Reliable isolation.** Cases must work independently in supported orders and parallel modes. Flag leaked state, uncontrolled time or randomness, live external dependencies, sleeps, and unawaited work when they create credible flakiness.
- **10. Resilient expectations.** Prefer observable contracts over private call sequences, incidental ordering, source-text matching, and oversized snapshots. Exact formatting, ordering, or interactions are valid when the contract requires them.
- **11. Maintainable cost.** Names, inputs, and setup should explain the scenario and failure. Flag excessive fixtures, opaque helpers, or expensive setup when simplification preserves confidence and offers concrete maintenance or runtime benefits.
- **12. Explicit Rails cases.** Prefer separate test blocks for distinct scenarios. Avoid loops generating tests or running scenarios inside one test: failure line numbers should identify a case with visible inputs, without reconstructing dynamic parameters. Share setup through helpers where useful.

## Review output

Report actionable findings by impact with requirement ID(s), file and line, the missed bug or maintenance problem, and the smallest useful correction. Cite both locations for redundancy. Report no findings when appropriate; omit a checklist of passes.

Run focused tests when needed to resolve uncertainty, following project guidance. State scope, tests run, and unverified assumptions. Passing tests or coverage percentages do not prove adequate coverage.
