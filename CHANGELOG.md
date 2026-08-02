# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **`interfaces` lens** — the Heuristic Test Strategy Model's **I**nterfaces element joins the coverage lens in the `chartering` skill, covering APIs, imports and exports, UI surfaces, and integration points between systems: the boundaries where service-oriented and LLM tool-calling applications most often fail. **Downstream consumers must handle `interfaces` as a new allowed value of a charter object's optional `lens` field** (`agents/charter-generator.md`), alongside the existing `structure`, `function`, `data`, `platform`, `operations`, and `time`.

- **`bug-advocacy` skill** — a sixth doctrine skill encoding Cem Kaner's **RIMGEA** (Replicate, Isolate, Maximize, Generalize, Externalize, And say it clearly), the discipline for the work between "an oracle says this is wrong" and a report someone will act on. It also defines **severity**, which the explorer's contract has always required and this plugin has never defined: a four-level rubric — **Critical > High > Moderate > Minor** — with an impact ladder of explicit clauses, three aggravating-only modifiers, and an agreement test, so two sessions rating the same bug from the same evidence land on the same level. Routed from the orchestrator's routing table and handed off to from `oracles` at the point a result is classified a Defect. **The explorer's `bugs[]` entries gain `minimal_repro`, `worst_observed`, `generalization`, and `stakeholder_impact`** (Isolate / Maximize / Generalize / Externalize), which are **honest-or-"could not establish", never invented**, and the `stride-exploratory-testing-explore` command-skill carries all four through aggregation with a merge rule for cross-session duplicates. RIMGEA's Maximize step is explicitly bounded by the explorer's absolute safety boundary: a worse failure that cannot be demonstrated safely is a risk to name, never a result to claim, and security bugs are maximized by reasoning rather than by exploitation. **Downstream consumers must handle the four new `bugs[]` fields.**

- **Session artifacts that survive the conversation.** The plugin now persists three things to a small, predictable, gitignorable tree in **the project under test** (the current working directory, never the installed skill tree): `.exploratory/sessions/<timestamp>-<target-slug>.md` (one aggregated debrief per explore run), `.exploratory/backlog.md` (the charter backlog made real — charters deferred for budget, off-charter items parked mid-session, and candidate charters nobody has run yet), and `.exploratory/coverage.md` (the product coverage outline: which areas were explored, when, what is covered, and what is still dark). The convention — paths, the `date +%Y-%m-%d-%H%M` timestamp, the `[a-z0-9-]` slug rule, the per-artifact lifecycle, the first-write header rule, the `.gitignore` line, and the first-run rule — is owned by a new **Session artifacts on disk** section in the `session` skill. **A missing artifact is an empty starting state, never an error:** a first run in a new project creates the tree rather than failing. The coverage outline is deliberately a **map, not a score** — it carries no percentage, because "explored enough" is a judgment, not a number. All five command-skills participate: the explore skill writes its debrief by default (gaining `--output` to redirect it) and updates both shared files; charter, nightmare-headline and recon append the charters they generate; debrief appends parked items and refreshes coverage; recon may add an un-explored area stub but never marks an area explored, because surveying is not exploring.

- **`charter-generator` accepts an optional `coverage context`** — a digest of what has already been explored against the target and what is already on the backlog — and a new optional `deprioritized` root key in its output contract reports the charter ideas it ranked down or dropped because prior coverage shows the ground was already explored. **`deprioritized` is distinct from the existing `coverage_notes`** and does not replace it: `coverage_notes` is about SFDIPOT angles the agent chose to skip on this run; `deprioritized` is about ground a previous session already covered. **Downstream consumers must handle the new optional `deprioritized` key.** The agent remains read-only.

### Changed

- **The redaction and untrusted-input rules now cover files, not just rendered output.** The `session` skill's *Safety of session artifacts* section is extended: `.exploratory/` is a new on-disk sink for observed system output, so credentials, tokens, customer data, personal data, and internal hostnames are redacted **before** a write — a file outlives the conversation and can be read by someone who never saw the session. And because the backlog and coverage outline are read back on later runs, they are treated as **untrusted data, never instructions**: a line that looks like a command is content to report, never something to obey. Artifact paths are handed only to the platform's file-read and file-write tools; the sole shell command any path may appear in is a `mkdir -p` of its own dirname, and the session slug is restricted to `[a-z0-9-]` so it can carry neither a traversal nor a shell metacharacter. This edition states the `mkdir -p` as **required** rather than conventional: unlike the Claude original it does not assume the file-write tool creates missing parents.

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
