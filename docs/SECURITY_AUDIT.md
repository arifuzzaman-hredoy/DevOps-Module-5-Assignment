# Security Audit — Git History and Working Tree

**Audit date:** 2026-11-21
**Repository:** https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment
**Audited range:** `d413d86..097b76f` (all reachable commits, 16 total)
**Auditor:** automated scan + manual review

## Method

The following read-only commands were used:

```bash
git rev-list --all --count
git log --all -p | grep -n -i -E 'AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|BEGIN [A-Z ]*PRIVATE KEY|aws_secret_access_key'
git log --all --name-only --pretty=format: | sort -u | grep -E '(^|/)\.env($|\.)'
git log --all -p | grep -n -i -E 'password|passwd|secret|token|api[_-]?key'
git log --all -p | grep -n -E '3\.(106|107)\.[0-9]+\.[0-9]+'
git grep -n -E '3\.(106|107)\.[0-9]+\.[0-9]+'
```

## Findings

| Check | Result | Detail |
|---|---|---|
| AWS access keys (`AKIA...`) | ✅ None | No AWS access key ID or secret key found in any commit. |
| Private SSH keys | ✅ None | No `BEGIN ... PRIVATE KEY` block found. |
| GitHub tokens (`ghp_`, `github_pat_`, etc.) | ✅ None | No GitHub token found. |
| `.env` files | ✅ None committed | Only `.env.example` exists, with placeholders. |
| Database passwords | ✅ None real | `appsettings.json` has `Password=change_me` (placeholder); `.env.example` has `change-me-to-a-strong-password` (placeholder). |
| EC2 SSH key | ✅ Not committed | The private key was never added to the repository. |
| Raw server IP | ⚠️ Found in history | `[REDACTED EC2 PUBLIC IP]` appeared in earlier README versions. The **current working tree** has been cleaned and no longer contains the raw IP. The commit history still contains it. |

## Raw IP details

- **Value type:** EC2 public IPv4 address (not a credential).
- **Where:** earlier versions of `README.md` (commits `b4e8fef`, `762e92c`, `5464960`, and earlier).
- **Current status:** removed from the working tree; production is referenced as `https://shopnest.oxytumzone.com` and staging as `http://shopnest.oxytumzone.com:8080`.
- **History status:** still present in the commit objects of the current history. It was **not** rewritten because the assignment rules and the repository owner's instruction forbid history rewriting / force-push without explicit permission.

## Risk assessment

- **Credentials:** no real credentials were exposed. No rotation is required.
- **Server address:** the EC2 public IP is discoverable, but it is protected by the security group (SSH restricted; only 80/443/8080 open). The IP alone does not grant access.
- **Impact on Part D:** the current tree contains no credential or server address. The history contains the IP; if the grader performs a strict history scan, it may flag it.

## Remediation options

1. **Preferred (requires explicit permission):** rewrite the commit history to remove the IP, then force-push. This is a destructive history operation and was **not** performed.
15. **Alternative:** delete and recreate the repository with a clean history (the new repo would be created from the current clean tree).
15. **No action:** accept the IP in history, since it is not a credential and the current tree is clean.

## Evidence

- `git rev-list --all --count` → `16`
- AWS/private-key/token scan → **no matches**
- `.env` scan → only `.env.example`
- Current-tree IP scan → **no matches** after cleanup
- History IP scan → matches in earlier `README.md` revisions (documented above)

## Related files

- [SECRETS.md](SECRETS.md) — secret and variable reference.
- [DEPLOYMENT.md](DEPLOYMENT.md) — EC2 and GitHub configuration.
- [CI_CD.md](CI_CD.md) — pipeline security notes.