# V2 Improvements Over V1 (Feature & Architecture)

**V1** = `ai-claude-platform` — centralized AI workflow assets with **per-team** folders and **team-first** setup.  
**V2** = `ai-sdlc-platform` — **canonical NL + SDLC engine** with **unified** agents, skills, stages, workflows, and a **single** `sdlc` CLI.

This document explains **why V2 is superior for ongoing SDLC work** across feature dimensions. Pair it with [Migrating From V1 To V2](Migrating_From_V1_to_V2.md) for practical cutover steps.

## 1. Platform architecture

| Aspect | V1 | V2 advantage |
|--------|-----|----------------|
| Source layout | Platform split by **team** (`backend/`, `qa/`, …) with duplicated patterns | **One tree**: `rules/`, `agents/`, `skills/`, `stages/`, `workflows/`, `cli/` — **single definition** of behavior |
| Consumption model | Projects symlink **one team at a time** from V1 | Projects symlink **V2 once**; **role + stack** select behavior (`sdlc use`) without switching platform folders |
| Extension | Additions scattered by team | **`extension-templates/`** + registries — add **roles**, **agents**, **skills**, **stages** with documented extension points ([Architecture](Architecture.md)) |
| Canonical policy | Implicit | Explicit: [CANONICAL_REPO_AND_INTERFACES](CANONICAL_REPO_AND_INTERFACES.md) — **no second copy** of orchestrators or skills |

**Why it matters:** less drift between teams, easier platform upgrades, and clearer ownership of “the” pipeline definition.

## 2. CLI and automation

| Aspect | V1 | V2 advantage |
|--------|-----|----------------|
| Entry points | `scripts/doctor.sh`, `setup.sh`, various script names | **`sdlc`** front end — **40+** subcommands, same scripts whether human or CI runs them ([Commands](Commands.md)) |
| Context | Team-centric mental model | **`sdlc use`**, **`sdlc context`**, **`sdlc run <stage>`**, **`sdlc flow`** — aligned to **15 stages** and **named workflows** |
| Diagnostics | Doctor script | **`sdlc doctor`** (optional **`--verbose`**) — tools, hooks, memory, registries, ADO |
| Cost visibility | Token themes in V1 docs | **`sdlc cost`**, **`sdlc tokens`** — per-stage and portfolio visibility |
| Natural language vs CLI | IDE chat and scripts described separately | **Both**: [Commands](Commands.md) documents **NL and CLI together** — use **`/project:*`**, plain-language asks, or **`sdlc route "<text>"`**; delegate **`sdlc module load`** / **`sdlc memory semantic-*`** to the assistant when you do not type flags yourself. CLI remains authoritative; hooks and CI call the same binaries. |

**Why it matters:** predictable commands, easier onboarding, automation that mirrors what developers type locally, and **one** behavior whether the user prefers chat or terminal.

## 3. SDLC coverage (stages, gates, workflows)

| Aspect | V1 | V2 advantage |
|--------|-----|----------------|
| Pipeline shape | Strong **backend SDLC**, **QA STLC**, **perf** pipelines in team orchestrators | **15 numbered stages** (`01`–`15`) **shared** across roles — one mental map ([SDLC_Flows](SDLC_Flows.md)) |
| Gates | G1–G10 described in V1 README | Same **ask-first, advisory** philosophy — **formalized** in V2 rules and stage docs with **metrics hooks** where applicable |
| Workflows | Per-team orchestrator markdown | **`workflows/*.yaml`** — **nine** named flows (e.g. `full-sdlc`, `quick-fix`, `perf-cycle`, `plan-design-implement`) runnable via **`sdlc flow`** |

**Why it matters:** one progression from intake to close, with explicit workflow switches for hotfixes and specialized cycles.

## 4. Agents, skills, and rules

| Aspect | V1 | V2 advantage |
|--------|-----|----------------|
| Inventory | Agents/skills spread under team dirs | **~52 agents**, **~35 atomic skills**, **4 orchestrators**, **`agent-registry.json`** — **tiered** model ([Agents_Skills_Rules](Agents_Skills_Rules.md)) |
| Rules | Global + team rules in V1 | **`rules/`** — **26** global org rules as **canonical** source; stacks under **`stacks/`** |
| IDE rules | Cursor + Claude supported | **`.cursor/rules`** + **`.claude/rules`** symlink to same content; includes **user-manual sync** hints when editing platform files |

**Why it matters:** fewer “which copy is authoritative?” questions and better scale as you add domains.

## 5. Memory and knowledge

| Aspect | V1 | V2 advantage |
|--------|-----|----------------|
| Project memory | `.claude/memory/` files | **`.sdlc/memory/`** — git-friendly structured memory **plus** orchestration integration |
| Semantic recall | Not a first-class unified story in V1 README | **SQLite semantic index** — **ranked retrieval**, lifecycle governance, **`sdlc memory semantic-*`**; **team JSONL** in git + **auto-sync** on commit/pull ([Persistent_Memory](Persistent_Memory.md), [Commands](Commands.md)) |
| Module intelligence | N/A at same level | **`sdlc module load` / `validate` / `report`** — **token-efficient** slices instead of loading everything |

**Why it matters:** better reuse of past decisions and lower token load for large codebases; **hooks** keep module KB + semantic export aligned with commits when configured.

## 6. Stories, templates, and Azure DevOps

| Aspect | V1 | V2 advantage |
|--------|-----|----------------|
| Story authoring | Templates exist across teams | **4-tier story system** — **`sdlc story create`**, **`validate`**, **`push`** to ADO — consistent IDs and fields ([Commands](Commands.md)) |
| Missing PRD / parent context | Easy to fill templates with guessed prose | **Governed authoring**: [STORY_TEMPLATE_REGISTRY.md](../templates/story-templates/STORY_TEMPLATE_REGISTRY.md) defines **`USER_INPUT_REQUIRED`** when a section has no PRD/parent support; generator/validator **skills** must **not** invent filler — prompt the author instead. |
| ADO alignment | MCP + REST patterns in V1 | **`sdlc ado`** suite — create, list, show, update, link, comment, sync, **push-story** — documented in [ADO_MCP_Integration](ADO_MCP_Integration.md) |
| Traceability | Strong principle | **AB#** and merge trace hooks reinforced in [PR_Merge_Process](PR_Merge_Process.md) |

**Why it matters:** faster path from Markdown in repo to work items, with less custom glue per team.

## 7. QA and orchestrators

| Aspect | V1 | V2 advantage |
|--------|-----|----------------|
| QA pipeline | Rich QA tree in V1 (`qa/orchestrator/`, skills) | **QA orchestrator** integrated with **semantic memory** writes and shared **`orchestrator/shared/`** libraries |
| Commands | Team commands in docs | **`sdlc qa`** — start, status, approve, kb, archive, health ([Commands](Commands.md)) |

**Why it matters:** same orchestration patterns as other domains, easier to maintain.

## 8. RPI (research / plan / implement)

| Aspect | V1 | V2 advantage |
|--------|-----|----------------|
| Safety model | RPI described in V1 README | **`sdlc rpi`** — **research → plan → implement → verify** with explicit status ([Commands](Commands.md)) |

**Why it matters:** guarded implementation for sensitive changes, consistent across stacks.

## 9. Git hooks and quality

| Aspect | V1 | V2 advantage |
|--------|-----|----------------|
| Hooks | Global enforcement scripts | **18 hooks** — **5 hard-block** (secrets, trace, commit format, branch, token guard) + **13 advisory** ([System_Overview](System_Overview.md)); pre-commit can **auto-sync** module KB + semantic memory export ([Commands](Commands.md)) |
| Registry generation | Manual or ad hoc | **`scripts/regenerate-registries.sh`** refreshes **agents/CAPABILITY_MATRIX.md**, **skills/SKILL.md**, **.claude/commands/COMMANDS_REGISTRY.md** — creates **`.claude/commands`** if missing so fresh clones do not fail |
| Docs | Large V1 README | **`User_Manual/`** as **single source of truth** + **`manual.html`** offline reader |

**Why it matters:** policy is bundled with the same repo you upgrade, with discoverable manual pages and **CI-friendly** registry regeneration.

## 10. IDE and developer experience

| Aspect | V1 | V2 advantage |
|--------|-----|----------------|
| Slash commands | Documented global + team commands | **50+** slash commands aligned to stages and flows (**`/project:*`**) plus optional **NL** in chat for the same outcomes ([Commands](Commands.md)) |
| Plugin | Dual IDE story | **`plugins/ide-plugin/`** — install path integrated into **setup** |
| Documentation UX | README-centric | **Dedicated manual** + search in **manual.html** |

**Why it matters:** less time hunting README sections; same commands whether you use Cursor or Claude Code.

## 11. Roles and organizational fit

| Aspect | V1 | V2 advantage |
|--------|-----|----------------|
| Teams | 6 teams | **8 roles** — adds explicit **UI** and splits leadership into **TPM** vs **Boss** where useful ([Getting_Started](Getting_Started.md)) |
| Stacks | Per-team conventions | **`stacks/`** — **6** stack packs (e.g. Java, Kotlin, Swift, React Native, JMeter, Figma) |

**Why it matters:** clearer skill boundaries for design and leadership without duplicating platform trees.

## 12. When V1 is still referenced

- **Historical** PRs, tickets, or runbooks that cite `ai-claude-platform` paths remain valid as archives.
- **Product-specific** assets that never belonged in the platform should stay in the **application** repo after migration.

---

## Summary table

| Dimension | V1 strength | V2 evolution |
|-----------|-------------|--------------|
| Organization | Clear per-team packs | **Unified canonical platform** |
| CLI / automation | Scripts + setup | **`sdlc` everywhere** |
| Pipeline | Strong multi-pipeline story | **15 stages + YAML workflows** |
| Memory | File-based team memory | **`.sdlc/memory` + semantic layer + module slices** |
| NL vs CLI | Chat-first or terminal-first only | **Documented NL + CLI together** ([Commands](Commands.md)) |
| Story quality | Template-only | **`USER_INPUT_REQUIRED`** when sources are missing ([STORY_TEMPLATE_REGISTRY](../templates/story-templates/STORY_TEMPLATE_REGISTRY.md)) |
| Work items | ADO + MCP | **Story CLI + fuller `sdlc ado`** |
| Quality | Hooks + gates | **Same philosophy**, more **centralized** enforcement surface |
| Docs | Monolithic README | **`User_Manual/` + manual.html** |

**Bottom line:** V2 is not a different product goal — it is **the same philosophy** (AI assists, humans approve; traceability; ADO) with **stricter unification**, **richer automation**, and **better scale** for multi-team SDLC.
