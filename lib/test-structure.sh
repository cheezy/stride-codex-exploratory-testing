#!/usr/bin/env bash
# Structure smoke test for the stride-codex-exploratory-testing plugin.
#
# Asserts the plugin ships every file the Codex CLI edition requires: a
# valid manifest with the four Codex keys, all seven command-skills, all
# six doctrine skills, both agents, the three README-referenced fixtures,
# and the root docs (including AGENTS.md and both installers). Codex ships
# NO command files, so there is no commands/ check. A last section pins
# what the explorer card in agents/explorer.md says. Pure shell + python3
# (for JSON) — no network, no jq.
#
# Exit code: 0 if every check passes; 1 if any check fails.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

PASS=0
FAIL=0

ok()   { PASS=$(( PASS + 1 )); printf '  ✓  %s\n' "$1"; }
nope() { FAIL=$(( FAIL + 1 )); printf '  ✗  %s\n     %s\n' "$1" "${2:-}"; }

printf 'stride-codex-exploratory-testing structure smoke test\n'
printf 'plugin root: %s\n\n' "$PLUGIN_ROOT"

# --- Manifest --------------------------------------------------------------

MANIFEST="${PLUGIN_ROOT}/.codex-plugin/plugin.json"
if [ -f "$MANIFEST" ]; then
  if python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$MANIFEST" 2>/tmp/scet-manifest.err; then
    ok ".codex-plugin/plugin.json exists and is valid JSON"
    if python3 -c "
import json, sys
d = json.load(open(sys.argv[1]))
if not isinstance(d, dict):
    sys.exit(1)
missing = [k for k in ('name', 'description', 'version', 'skills') if k not in d]
sys.exit(1 if missing else 0)
" "$MANIFEST"; then
      ok "plugin.json has the four Codex keys (name, description, version, skills)"
    else
      nope "plugin.json is missing one of: name, description, version, skills" ""
    fi
  else
    nope "plugin.json is not valid JSON" "$(cat /tmp/scet-manifest.err)"
  fi
  rm -f /tmp/scet-manifest.err
else
  nope ".codex-plugin/plugin.json not found" "$MANIFEST"
fi

# --- Command-skills (Codex has no commands/; entry is skill activation) -----

for skill in \
  stride-exploratory-testing-charter \
  stride-exploratory-testing-nightmare-headline \
  stride-exploratory-testing-explore \
  stride-exploratory-testing-recon \
  stride-exploratory-testing-debrief \
  stride-exploratory-testing-pair \
  stride-exploratory-testing-harden; do
  if [ -f "${PLUGIN_ROOT}/skills/${skill}/SKILL.md" ]; then
    ok "skills/${skill}/SKILL.md exists"
  else
    nope "skills/${skill}/SKILL.md is missing" ""
  fi
done

# --- Doctrine skills --------------------------------------------------------

for skill in stride-exploratory-testing chartering heuristics oracles session bug-advocacy; do
  if [ -f "${PLUGIN_ROOT}/skills/${skill}/SKILL.md" ]; then
    ok "skills/${skill}/SKILL.md exists"
  else
    nope "skills/${skill}/SKILL.md is missing" ""
  fi
done

# Count only real SKILL.md files (the .gitkeep placeholder is ignored):
# 7 command-skills + 6 doctrine skills = 13.
SKILL_COUNT=$(find "${PLUGIN_ROOT}/skills" -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')
if [ "$SKILL_COUNT" -eq 13 ]; then
  ok "exactly 13 SKILL.md files present (.gitkeep ignored)"
else
  nope "expected 13 SKILL.md files, found ${SKILL_COUNT}" ""
fi

# --- Agents (Codex: bare *.md files, no commands/ directory) -----------------

for agent in charter-generator explorer; do
  if [ -f "${PLUGIN_ROOT}/agents/${agent}.md" ]; then
    ok "agents/${agent}.md exists"
  else
    nope "agents/${agent}.md is missing" ""
  fi
done

# Count only *.md agent files (the .gitkeep placeholder is ignored).
AGENT_COUNT=$(find "${PLUGIN_ROOT}/agents" -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')
if [ "$AGENT_COUNT" -eq 2 ]; then
  ok "exactly 2 agent files present (.gitkeep ignored)"
else
  nope "expected 2 agent files, found ${AGENT_COUNT}" ""
fi

# Codex ships no command files: assert there is no commands/ directory.
if [ -d "${PLUGIN_ROOT}/commands" ]; then
  nope "unexpected commands/ directory (Codex ships no command files)" "${PLUGIN_ROOT}/commands"
else
  ok "no commands/ directory (correct for Codex)"
fi

# --- Fixtures (referenced by README.md) ------------------------------------

for fixture in example-charters.md example-session-sheet.md example-debrief.md; do
  if [ -f "${PLUGIN_ROOT}/fixtures/${fixture}" ]; then
    ok "fixtures/${fixture} exists"
  else
    nope "fixtures/${fixture} is missing" ""
  fi
done

# --- Root docs and installers ----------------------------------------------

for doc in README.md HEURISTICS.md CHANGELOG.md LICENSE AGENTS.md install.sh install.ps1; do
  if [ -f "${PLUGIN_ROOT}/${doc}" ]; then
    ok "${doc} exists"
  else
    nope "${doc} is missing" ""
  fi
done

# --- Content pins: explorer card -------------------------------------------
#
# The first checks here on what an agent's prose says; the sections above
# cover existence and manifest keys, and test-frontmatter.sh the
# frontmatter. agents/explorer.md carries an inline card with every rule the
# explorer needs to rate a bug and end a session, so a skill that fails to
# load costs nothing. The checks hold the card right after the safety
# boundary and under 4,096 bytes, tie its severity words to bug-advocacy's
# four levels and its stop rules to the stop_reason row, and keep the skill
# references path-free. Later tasks in the port append here. The files are
# only read, never executed.
printf '\n'
EXPLORER="${PLUGIN_ROOT}/agents/explorer.md"
ADVOCACY="${PLUGIN_ROOT}/skills/bug-advocacy/SKILL.md"

if [ -f "$EXPLORER" ] && [ -f "$ADVOCACY" ]; then
  # Marker lines: count, first line number, and whether each is exactly the
  # marker comment. Outputs: starts ends start_line end_line exact(0/1).
  set -- $(awk '
    { sub(/\r$/, "") }
    /explorer-card:start/ { s++; if (!sl) sl = NR; if ($0 != "<!-- explorer-card:start -->") bad = 1 }
    /explorer-card:end/   { e++; if (!el) el = NR; if ($0 != "<!-- explorer-card:end -->")   bad = 1 }
    END { print s+0, e+0, sl+0, el+0, (bad ? 0 : 1) }' "$EXPLORER")
  M_START=$1; M_END=$2; L_START=$3; L_END=$4; M_EXACT=$5
  if [ "$M_START" -eq 1 ] && [ "$M_END" -eq 1 ] && [ "$L_START" -lt "$L_END" ] && [ "$M_EXACT" -eq 1 ]; then
    CARD_OK=1
    ok "explorer card has exactly one start and one end marker, in order"
  else
    CARD_OK=0
    nope "explorer card markers are invalid" \
      "start=${M_START} end=${M_END}; need exactly one of each, start before end, each alone on its line"
  fi

  card_text() {
    [ "$CARD_OK" -eq 1 ] || return 0
    awk '/explorer-card:start/{f=1} f{print} /explorer-card:end/{f=0}' "$EXPLORER"
  }

  # Position: the card is the first section after the safety boundary.
  set -- $(awk '
    { sub(/\r$/, "") }
    /^## / && n < 3 { n++; h[n] = NR; t[n] = $0 }
    END {
      ok = (t[1] ~ /^## Safety boundary/ && t[2] ~ /^## Explorer card/)
      print (ok ? 1 : 0), h[2]+0, h[3]+0
    }' "$EXPLORER")
  if [ "$CARD_OK" -eq 1 ] && [ "$1" -eq 1 ] && [ "$2" -eq $(( L_START + 1 )) ] && [ "$L_END" -lt "$3" ]; then
    ok "explorer card sits right after the safety boundary"
  else
    nope "explorer card is not the first section after the safety boundary" \
      "need '## Safety boundary', then the start marker with '## Explorer card' on the next line, then the end marker before the next section"
  fi

  # Byte cap, measured exactly as: awk '/explorer-card:start/,/explorer-card:end/' | wc -c
  CARD_BYTES=$(card_text | wc -c | tr -d ' ')
  if [ "$CARD_BYTES" -ge 1 ] && [ "$CARD_BYTES" -le 4096 ]; then
    ok "explorer card is within 4096 bytes"
  else
    nope "explorer card is outside 1-4096 bytes" "measured ${CARD_BYTES} bytes"
  fi

  # Severity: the card's token line, rank line and ladder bullets must each
  # equal bug-advocacy's four-levels table, in order.
  TABLE=$(tr -d '\r' < "$ADVOCACY" | awk '
    /^### The four levels/ { f = 1; next }
    /^### / { f = 0 }
    f && /^\| \*\*[A-Za-z]+\*\* \|/ { s = $0; sub(/^\| \*\*/, "", s); sub(/\*\*.*/, "", s); o = o (o == "" ? "" : " ") s }
    END { print o }')
  RANK=$(tr -d '\r' < "$ADVOCACY" | awk '
    match($0, /Rank order is \*\*[A-Za-z >]+\*\*/) {
      s = substr($0, RSTART, RLENGTH); sub(/^Rank order is \*\*/, "", s); sub(/\*\*$/, "", s); gsub(/ > /, " ", s); print s; exit
    }')
  C_ENUM=$(card_text | tr -d '\r' | awk '
    /^Severity words: / && !seen { seen = 1; s = $0; while (match(s, /`[A-Za-z]+`/)) { o = o (o == "" ? "" : " ") substr(s, RSTART + 1, RLENGTH - 2); s = substr(s, RSTART + RLENGTH) } }
    END { print o }')
  C_RANK=$(card_text | tr -d '\r' | awk '
    /^Severity order: / { s = $0; sub(/^Severity order: /, "", s); gsub(/ > /, " ", s); print s; exit }')
  C_LADDER=$(card_text | tr -d '\r' | awk '
    /^- \*\*[A-Za-z]+\*\*: / { s = $0; sub(/^- \*\*/, "", s); sub(/\*\*.*/, "", s); o = o (o == "" ? "" : " ") s }
    END { print o }')
  if [ "$(echo $TABLE | wc -w | tr -d ' ')" -eq 4 ] && [ "$RANK" = "$TABLE" ] && [ "$C_ENUM" = "$TABLE" ] \
     && [ "$C_RANK" = "$TABLE" ] && [ "$C_LADDER" = "$TABLE" ]; then
    ok "explorer card severity tokens, rank and ladder match bug-advocacy's four levels"
  else
    nope "explorer card severity drifted from bug-advocacy" \
      "table='${TABLE}' rank='${RANK}' card tokens='${C_ENUM}' card rank='${C_RANK}' card ladder='${C_LADDER}'"
  fi

  # stop_reason: the card's stop values and the output contract's must be the same set.
  C_STOPS=$(card_text | tr -d '\r' | awk '
    /^- `[a-z_]+`: / { s = $0; sub(/^- `/, "", s); sub(/`.*/, "", s); print s }' | LC_ALL=C sort -u)
  K_STOPS=$(tr -d '\r' < "$EXPLORER" | awk '
    index($0, "| `stop_reason` |") == 1 {
      s = substr($0, length("| `stop_reason` |") + 1)
      while (match(s, /`[a-z_]+`/)) { print substr(s, RSTART + 1, RLENGTH - 2); s = substr(s, RSTART + RLENGTH) }
    }' | LC_ALL=C sort -u)
  if [ -n "$C_STOPS" ] && [ "$C_STOPS" = "$K_STOPS" ]; then
    ok "explorer card stop rules name exactly the output contract's stop_reason values"
  else
    ONLY_CARD=$(LC_ALL=C comm -23 <(printf '%s\n' "$C_STOPS") <(printf '%s\n' "$K_STOPS") | paste -sd ' ' -)
    ONLY_CONTRACT=$(LC_ALL=C comm -13 <(printf '%s\n' "$C_STOPS") <(printf '%s\n' "$K_STOPS") | paste -sd ' ' -)
    nope "explorer card stop_reason values differ from the output contract" \
      "in card only: [${ONLY_CARD}] in contract only: [${ONLY_CONTRACT}]"
  fi

  # RIMGEA mapped onto bugs[] fields, and the three oracle verdicts.
  MISSING_MAP=""
  for needle in '- Replicate:' '- Isolate, into `minimal_repro`:' '- Maximize, into `worst_observed`:' \
                '- Generalize, into `generalization`:' '- Externalize, into `stakeholder_impact`:' \
                '- And say it clearly:' 'Verdicts: Defect; Known-bad-but-expected (' '); Acceptable.'; do
    card_text | grep -qF -e "$needle" || MISSING_MAP="${MISSING_MAP} [${needle}]"
  done
  if [ -z "$MISSING_MAP" ]; then
    ok "explorer card maps RIMGEA onto bugs[] fields and names the oracle verdicts"
  else
    nope "explorer card is missing RIMGEA or oracle-verdict text" "missing:${MISSING_MAP}"
  fi

  # Severity rules past the ladder (a tie, the modifiers and how they
  # combine, likelihood, an unknown impact) and the three oracle kinds.
  MISSING_RULES=""
  for needle in 'Clauses at two levels both match: take the higher, for what you demonstrated only.' \
                'Reach (' 'Avoidability (' 'Persistence (' 'A single modifier changes nothing' \
                'two or more raise it by one level, never more' 'never lift one to Critical' 'Minor is the lowest' \
                'Likelihood plays no part in the level' 'never as Critical or High' \
                'open `stakeholder_impact` with "Provisional"' \
                'Kinds, tried in turn: Never/Always invariants (' '); consistency oracles (' '); approximations ('; do
    card_text | grep -qF -e "$needle" || MISSING_RULES="${MISSING_RULES} [${needle}]"
  done
  if [ -z "$MISSING_RULES" ]; then
    ok "explorer card carries the tie, modifier, likelihood and unknown-impact rules and the three oracle kinds"
  else
    nope "explorer card is missing severity or oracle rule text" "missing:${MISSING_RULES}"
  fi

  # Skill references. Codex gives a custom agent the skills its parent
  # session has, listed by name with each one's path; nothing documents a
  # skills/<name>/SKILL.md path resolving from the project directory, where
  # the agent runs. So such a path is refused anywhere in the file, and each
  # skill is named instead.
  REL_REFS=$(tr -d '\r' < "$EXPLORER" | awk '/skills\/[a-z-]+\/SKILL\.md/ { c++ } END { print c+0 }')
  if [ "$REL_REFS" -eq 0 ]; then
    ok "agents/explorer.md names no skill by a skills/<name>/SKILL.md path"
  else
    nope "agents/explorer.md names a skill by a skills/<name>/SKILL.md path" \
      "${REL_REFS} line(s); name the skill instead, since Codex documents no project-relative path to an installed skill"
  fi

  MISSING_BY_NAME=""
  for skill in heuristics oracles bug-advocacy session; do
    pat='- **`'"$skill"'`** (skill, by name)'
    hits=$(tr -d '\r' < "$EXPLORER" | awk -v p="$pat" 'index($0, p) == 1 { c++ } END { print c+0 }')
    [ "$hits" -eq 1 ] || MISSING_BY_NAME="${MISSING_BY_NAME} ${skill}"
  done
  if [ -z "$MISSING_BY_NAME" ]; then
    ok "explorer skill references name each skill for Codex to find by name"
  else
    nope "explorer skill reference not in by-name form" "for:${MISSING_BY_NAME}"
  fi
else
  nope "explorer card checks need agents/explorer.md and skills/bug-advocacy/SKILL.md" ""
fi

# --- summary ----------------------------------------------------------------

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
