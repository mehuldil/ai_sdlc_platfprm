# Public mirror sync (Azure → GitHub)

The **canonical** platform lives on **Azure DevOps** (`AI-sdlc-platform`). The **GitHub** repo (`ai_sdlc_platform`) is a **public mirror**: same tree, without internal organization clone URLs and with neutral doc wording where needed.

## Workflow

1. Commit and push changes on **Azure** first.
2. Clone or update your local **public mirror** checkout (sibling folder is easiest).
3. From the **Azure** repo root, run:

```bash
bash scripts/mirror-public/sync-to-public-mirror.sh /path/to/AI_SDLC_Platform
```

Default destination if you omit the argument: `../AI_SDLC_Platform` (relative to the Azure repo root).

4. Review `git diff` in the mirror, then commit and push **GitHub**.

5. Regenerate the offline manual in the mirror (embeds doc text):

```bash
cd /path/to/AI_SDLC_Platform
node User_Manual/build-manual-html.mjs
```

## What the script does

1. **`rsync`** from the Azure working tree into the mirror directory (excludes `.git`, secrets, etc. — see `rsync-excludes.txt`).
2. **Neutralizes** common internal URLs in `*.md` and `User_Manual/*.html` (not the generated JSON blob in `manual.html` — regenerate that with Node).
3. **Overlays** curated files from `scripts/mirror-public/overlays/` (GitHub clone wording, neutral `User_Manual` hub, etc.). Edit those overlays in the **Azure** repo when public wording should change.

## Environment overrides

| Variable | Default | Purpose |
|----------|---------|---------|
| `PUBLIC_MIRROR_GITHUB_CLONE` | `https://github.com/YOUR_GITHUB_USER/ai_sdlc_platform.git` | Replacement for the internal Azure HTTPS clone URL in bulk sed |
| `PUBLIC_MIRROR_DRY_RUN` | empty | Set to `1` to pass `--dry-run` to rsync only |

## Safety

- Run from a **clean** `git status` on both sides when possible.
- Use `PUBLIC_MIRROR_DRY_RUN=1 bash scripts/mirror-public/sync-to-public-mirror.sh …` to preview rsync.

## Do not edit the mirror as the source of truth

- **Always commit and push on Azure DevOps first.** The public GitHub tree is a **mirror**, not a second product.
- If you change files **only** in the mirror, they will be **overwritten** on the next `sync-to-public-mirror.sh` from Azure (or drift silently until someone notices).
- For doc wording that should differ on GitHub only, add or edit files under **`scripts/mirror-public/overlays/`** in the **Azure** repo, then re-sync.
