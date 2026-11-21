# Security Audit — Git History and Working Tree

**Audit date:** 2026-11-21
**Repository:** https://github.com/arifuzzaman-hredoy/DevOps-Module-5-Assignment
**Audit scope:** all reachable commits in the current repository (34 commits at the time of audit). The scan covered all refs; it was not limited to a single commit range.
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
| Raw server IP | ✅ Removed | An EC2 public IPv4 address ([REDACTED EC2 PUBLIC IP]) appeared in earlier README versions. The Git history rewrite was completed; the IP was removed from all reachable history of the four branches and tag `v1.0.0`. GitHub may retain unreferenced objects or old Actions logs. |

## Status summary

- **Current working tree:** no occurrence of the previously exposed raw EC2 IPv4 address. Production is referenced as `https://shopnest.oxytumzone.com`; staging is documented as `http://shopnest.oxytumzone.com:8080`.
- **Git history:** the history rewrite was completed on 2026-11-21. The four branches (`main`, `evidence/github-copilot`, `evidence/test-failure`, `evidence/yaml-syntax-failure`) and tag `v1.0.0` were rewritten and force-pushed. The IP was removed from all reachable history.
- **Credentials:** no AWS keys, private SSH keys, GitHub tokens, or real passwords were detected. No credential rotation is required.
- **GitHub:** PRs #2, #3, and #4 remain open. Branch protection was restored (`allow_force_pushes: false`). GitHub may retain unreferenced objects or old Actions logs until garbage collection.

## Raw IP details

- **Value type:** EC2 public IPv4 address (not a credential).
- **Where:** earlier versions of `README.md` (commits `b4e8fef`, `762e92c`, `5464960`, and earlier).
- **Current status:** removed from the current working tree and from all reachable history of the four branches and tag `v1.0.0`.
- **History status:** the rewrite was completed on 2026-11-21. The old commit SHAs are no longer referenced by the branches/tags. GitHub may retain unreferenced objects or old Actions logs until garbage collection.

## Risk assessment

- **Credentials:** no real credentials were exposed. No rotation is required.
- **Server address:** the EC2 public IP is discoverable, but it is protected by the security group (SSH restricted; only 80/443/8080 open). The IP alone does not grant access.
- **Impact on Part D:** the current working tree and reachable history contain no occurrence of the previously exposed raw EC2 IPv4 address and no credential. GitHub may retain unreferenced objects or old Actions logs; a direct SHA URL may still work until garbage collection.

## Remediation status

1. **Completed:** the history rewrite was completed on 2026-11-21. The four branches and tag `v1.0.0` were rewritten and force-pushed. Branch protection was restored (`allow_force_pushes: false`).
2. **Optional:** if a complete purge of unreferenced objects is required, contact GitHub Support to request garbage collection.
3. **No further action:** the current tree and reachable history are clean.

## Evidence

- `git rev-list --all --count` → `34`
- AWS/private-key/token scan → **no matches**
- `.env` scan → only `.env.example`
- Current-tree scan for the previously exposed IP → **no matches**
- History scan across the four branches and tag → **no matches after rewrite**
- PRs #2, #3, #4 → **open**
- Branch protection → `allow_force_pushes: false`

## Related files

- [SECRETS.md](SECRETS.md) — secret and variable reference.
- [DEPLOYMENT.md](DEPLOYMENT.md) — EC2 and GitHub configuration.
- [CI_CD.md](CI_CD.md) — pipeline security notes.