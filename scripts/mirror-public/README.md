# Publishing a public distribution tree

Use this flow when you maintain a **full** platform checkout and want to prepare a **separate** directory or clone for **public** sharing (neutral clone URLs and curated doc overlays).

This is a deliberate **publish** step: review the diff, regenerate the offline manual, then commit and push from the public checkout.

## Workflow

1. Commit your changes in the **full** repository (your usual remote and branch).
2. Clone or update the **public** checkout (a sibling folder is convenient).
3. From the **full** repo root, run **one** of:

**Linux / macOS / Git Bash with `rsync`:**

```bash
bash scripts/mirror-public/sync-to-public-mirror.sh /path/to/public-checkout
```

Default destination if you omit the argument: `../AI_SDLC_Platform` (relative to the full repo root).

**Windows (no `rsync` on PATH):**

```powershell
powershell -File scripts/mirror-public/sync-to-public-mirror.ps1 -Dest C:\path\to\public-checkout
bash scripts/mirror-public/finish-public-mirror.sh /c/path/to/public-checkout
```

(`finish-public-mirror.sh` runs **neutralize** + **overlays** + **neutralize** again; requires **Python 3**.)

4. In the public checkout, review `git diff`, then regenerate the offline manual (it embeds doc text):

```bash
cd /path/to/public-checkout
node User_Manual/build-manual-html.mjs
```

5. Commit and push from the **public** checkout.

## What the scripts do

1. **Copy** from the full working tree into the public directory (`rsync` or `robocopy`; excludes `.git`, IDE-generated trees, team `stories/`, machine `.sdlc/`, secrets, etc. — see `rsync-excludes.txt`).
2. **Neutralize** internal names and clone URLs via `neutralize_public_mirror.py` (common text extensions plus `.env` examples).
3. **Overlay** curated files from `scripts/mirror-public/overlays/` (e.g. hub pages and metadata). Edit overlays in the **full** repo when public-facing wording should differ.

## Environment overrides

| Variable | Default | Purpose |
|----------|---------|---------|
| `PUBLIC_MIRROR_GITHUB_CLONE` | `https://github.com/YOUR_GITHUB_USER/ai_sdlc_platform.git` | Replacement for internal HTTPS clone URLs in bulk substitution |
| `PUBLIC_MIRROR_DRY_RUN` | empty | Set to `1` to pass `--dry-run` to rsync only |

## Safety

- Run from a **clean** `git status` on both sides when possible.
- Use `PUBLIC_MIRROR_DRY_RUN=1 bash scripts/mirror-public/sync-to-public-mirror.sh …` to preview rsync.

## Source of truth

- Treat the **full** repository as the place where platform behavior is authored.
- If you edit files **only** in the public checkout, they will be **overwritten** on the next publish run (or drift until someone notices).
- For wording that should differ only in the public tree, add or edit files under **`scripts/mirror-public/overlays/`** in the **full** repo, then publish again.

## CI parity

After publish, the public repo’s GitHub Actions workflow **Publish tree verify** runs:

- `node User_Manual/build-manual-html.mjs --check`
- `bash scripts/mirror-public/verify-public-no-vendor.sh`

Run the same commands locally before pushing when you change docs or overlays.
