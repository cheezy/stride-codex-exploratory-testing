# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **`interfaces` lens** — the Heuristic Test Strategy Model's **I**nterfaces element joins the coverage lens in the `chartering` skill, covering APIs, imports and exports, UI surfaces, and integration points between systems: the boundaries where service-oriented and LLM tool-calling applications most often fail. **Downstream consumers must handle `interfaces` as a new allowed value of a charter object's optional `lens` field** (`agents/charter-generator.md`), alongside the existing `structure`, `function`, `data`, `platform`, `operations`, and `time`.

### Changed

- **`SFDPOT` renamed to `SFDIPOT`** across the plugin — skills, agents, command-skills, fixtures, and docs. Bach's HTSM (v6.0, 2024) lists seven Product Elements; the six-letter `SFDPOT` the plugin cited is a superseded form of the same heuristic. The `Interfaces` row slots between `Data` and `Platform`; no existing row was renamed, reordered, or dropped. The charter object's `source` enum value is still the literal `sfdpot` — it is a wire value, not the acronym, and renaming it would break existing consumers. The `[0.1.0]` entry below needed no edit: it predates the lens and carries no occurrence of either spelling.
- **The `explorer` agent no longer reports numbers it cannot observe.** `session_sheet` drops `duration` and `tbs` (Task Breakdown Metric percentages) — a wall-clock measurement an agent has no way to take, whose presence contradicted the agent's own hard rule against fabricating a result. In their place it reports what it genuinely counts: `probe_budget`, `probes_attempted`, `probes_with_finding`, `on_charter_probes`/`off_charter_probes`, `tool_calls_used`, `heuristics_applied`, and `stop_reason`. An agent session is now bounded by an **agent-native budget** — a probe budget (default 12, band 8–20) and a tool-call ceiling (5 × the probe budget), whichever is reached first; a session blocked before its first probe reports those counters as zero rather than omitting them. The `session` skill keeps the 60–120 minute box and TBS for **human-run and paired** sessions and now states plainly that neither binds an agent session; the four stopping heuristics are unchanged in substance (bullet 2 now reads "The box or the budget is up"). **The `stride-exploratory-testing-explore` command-skill gains `--probes <count>`** for the per-session probe budget; **`--timebox <minutes>` keeps its unit** and is now documented as doing only what it always effectively did — deciding how many charters run (one session ≈ 90 minutes) — and is never passed to the explorer. **Downstream consumers that read `session_sheet.duration` or `session_sheet.tbs` must switch to the counts**; the `stride-exploratory-testing-debrief` command-skill is unaffected (it consumes unstructured tagged notes). The `fixtures/` session sheet and debrief are unchanged **in substance**: both still document a **human-run** session, which keeps the box and TBS under the new split. The session sheet gains only a preamble labelling it human-run, pointing at the agent-run contract, and a worked agent-run sheet beside the human one so the new contract has an example to pattern-match against.

## [0.1.0] - 2026-07-22

Initial release of `stride-codex-exploratory-testing` — the Codex CLI edition of
the Stride exploratory-testing plugin (the "explored" half of *Tested = Checked +
Explored*).

### Added

- **Manifest & packaging** — `.codex-plugin/plugin.json` (name, version,
  description, skills), MIT `LICENSE`, `.gitignore`, and POSIX/PowerShell
  installers (`install.sh`, `install.ps1`).
- **Codex root context** — `AGENTS.md` describing the plugin for Codex CLI.
- **Five doctrine skills** — `stride-exploratory-testing` (orchestrator),
  `chartering`, `heuristics`, `oracles`, and `session`.
- **Five command-skills** (activated by name; Codex has no slash commands) —
  `stride-exploratory-testing-charter`, `stride-exploratory-testing-nightmare-headline`,
  `stride-exploratory-testing-explore`, `stride-exploratory-testing-recon`, and
  `stride-exploratory-testing-debrief`.
- **Two agents** — `charter-generator` (ranked charters from a target) and
  `explorer` (runs one time-boxed session under an absolute safety boundary).
- **Documentation** — `README.md` (install, model, skill/agent reference,
  quick-start, attribution) and `HEURISTICS.md` (pointer to the `heuristics`
  skill catalog).
- **Fixtures** — worked `fixtures/example-charters.md`,
  `fixtures/example-session-sheet.md`, and `fixtures/example-debrief.md` built on
  a synthetic target; they double as templates and regression anchors.
- **Smoke-test harness** — `lib/test-structure.{sh,ps1}`,
  `lib/test-frontmatter.{sh,ps1}`, and `lib/test-all.{sh,ps1}`: offline
  structure + frontmatter validators (no network, no jq) that gate a release.

## Releasing (cross-repo sync)

This plugin ships through the shared **[stride-codex-marketplace](https://github.com/cheezy/stride-codex-marketplace)**
catalog, which **vendors** the full plugin tree under
`plugins/stride-codex-exploratory-testing/` and registers a `local` source in
`.agents/plugins/marketplace.json` (the catalog entry carries **no** version
field). The single source of truth for the version is this repo's
`.codex-plugin/plugin.json`; the marketplace README's Plugins table mirrors it.

To keep the plugin and marketplace in sync on every release, bump the version in
one place and let it propagate:

1. Bump `version` in `.codex-plugin/plugin.json` and add a new section here.
2. In `stride-codex-marketplace`, re-vendor this tree with
   `rsync -a --delete` (excluding `.git`, `.stride`, `.env`, and secret files) so
   the new `plugin.json` version moves with it.
3. Update the marketplace README Plugins-table version cell to match, then run
   the marketplace `RELEASE.md` node validator and secret scan.
4. Tag and publish both repos per their `RELEASE.md` steps.
