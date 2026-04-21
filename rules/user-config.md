# User Configuration Reference

Each user must provide Azure DevOps credentials and organization details. Configuration is stored in `env/.env`.

For interactive setup, run: `./cli/sdlc-setup.sh`

---

## Required Environment Variables

```yaml
# Azure DevOps
ADO_ORG: "your-ado-org"                              # Organization name
ADO_PROJECT: "YourAzureProject"                             # Project name
ADO_PROJECT_ID: "12345678-abcd-efgh-ijkl-..."      # Project GUID (from Project Settings)

# User Identity
ADO_USER_NAME: "Your Display Name"                  # Your name in ADO
ADO_USER_EMAIL: "user@example.com"                  # ADO login email
ADO_PAT: "your-personal-access-token"               # Personal Access Token (see below)

# Optional: MCP Integrations
WIKIJS_TOKEN: "wiki-api-token"                      # Wiki.js API token
ES_URL: "https://your-cluster:9243"                 # Elasticsearch endpoint
ES_USER: "elastic_user"                             # Elasticsearch username
ES_PWD: "elastic_password"                          # Elasticsearch password
```

---

## Creating a Personal Access Token (PAT)

1. Go to **Azure DevOps** → **User Settings** → **Personal Access Tokens**
2. Click **New Token**
3. Name: `ai-sdlc-platform`
4. Scopes: Grant these:
   - Work Items: `Read & Write`
   - Code: `Read`
   - Build: `Read`
   - Release: `Read`
5. Expiration: 90 days (recommended) or 1 year
6. Click **Create** and copy the token immediately (cannot be recovered)
7. Paste into `env/.env` as `ADO_PAT`

**Do NOT grant:** Delete, admin, or identity scopes (not needed, reduces security risk).

---

## Verifying Configuration

After setting up `env/.env`, verify credentials work:

```bash
./scripts/validate-config.sh
```

Or manually test:
```bash
export ADO_PAT="your-token"
export ADO_ORG="your-ado-org"
curl -s -u ":${ADO_PAT}" \
  "https://dev.azure.com/${ADO_ORG}/_apis/projects?api-version=7.0" | jq '.value | length'
```

Should return a number >= 0 with no errors.

---

## Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| 401 Unauthorized | Token expired or wrong org | Regenerate PAT, check `ADO_ORG` |
| 403 Forbidden | Missing required scopes | Recreate PAT with "Read & Write" for work items |
| Invalid project ID | Wrong GUID | Get correct ID from **Project Settings** in ADO |

---

## Security Practices

- Never commit `env/.env` to version control
- Never share your PAT in logs, Wiki, or comments
- Rotate PATs annually — create new, update `.env`, delete old in ADO
- Use short expiry (30 days) for temporary test tokens

---

**Last Updated**: 2026-04-11  
**Governed By**: AI-SDLC Platform
