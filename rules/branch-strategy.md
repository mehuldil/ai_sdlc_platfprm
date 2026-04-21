# Branch & PR Strategy

## Core Principle
**No fixed branching model. ALWAYS ASK the developer before creating, merging, or deleting any branch.**

## Multi-Repo Architecture
- Backend and Frontend developers work on DIFFERENT repositories
- Each developer may work on different branches within their repo
- NEVER assume which repo or branch a developer is working on
- ALWAYS confirm repo context before any git operation

## Before Creating a Branch — ASK:
1. Which repository? (present list of known repos or ask to specify)
2. Branch name? (suggest convention: feature/AB#<id>-<short-desc>, bugfix/AB#<id>-<short-desc>, hotfix/AB#<id>-<short-desc>)
3. Source branch? (main, develop, release/*, or specify)
4. Is this a feature, bugfix, hotfix, or release branch?

## Before Merging — ASK:
1. Target branch? (present options)
2. Merge strategy? (squash, merge commit, rebase)
3. Delete source branch after merge? (yes/no)
4. Reviewers assigned? (present team list)

## PR Rules — ASK:
1. Before creating: Target branch, title, description, reviewers
2. Before approving: Show all check statuses, ASK for approval
3. Before merging: Confirm strategy, confirm target
4. Comments: Draft → Show → ASK before posting

## Branch Naming Convention (SUGGESTED, not enforced):
- feature/AB#<id>-<short-description>
- bugfix/AB#<id>-<short-description>  
- hotfix/AB#<id>-<short-description>
- release/<version>
- Always confirm with developer before applying

## Protected Branch Rules:
- main/master: No direct push, PR only, requires review
- release/*: No direct push, PR only, requires QA sign-off
- develop: PR preferred, direct push only for small config changes (ASK first)

## Cross-Repo Coordination:
- When BE and FE changes are needed for same feature:
  1. ASK which repo goes first
  2. Track dependency in ADO with blocking tags
  3. Coordinate PR timing — ASK both teams

---
Last Updated: 2026-04-11
Governed By: your-ado-org AI SDLC Platform
