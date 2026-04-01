# Upstream Merge Guide

This fork diverges structurally from [upstream ArozOS](https://github.com/tobychui/arozos) in several ways. This document tracks those divergences so that pulling in new upstream commits can be done with clear expectations about where conflicts will arise and how to resolve them.

## Remotes

```
origin    git@github.com:neonspectra/monika-aroz.git   (our fork)
upstream  https://github.com/tobychui/arozos            (tobychui's repo)
```

## Merge Workflow

```bash
git fetch upstream
git merge upstream/master --no-commit
# Review changes against the divergence table below
# Resolve conflicts per the resolution strategy for each divergence
git commit
```

## Structural Divergences

| Divergence | What changed | Why | Conflict likelihood | Resolution |
|------------|-------------|-----|-------------------|------------|
| Default branch `master` → `main` | Branch rename | Convention | None (branch name only) | N/A |
| `docs/` marketing site deleted | Entire directory removed, replaced with real developer documentation | The `docs/` folder was a GitHub Pages marketing site, not documentation. We replaced it with structured dev docs (quickstart, architecture, API reference, etc.) | **High if upstream touches docs/** | Keep ours. Upstream's `docs/` is a marketing site we don't use. |
| `src/subservice/*` un-gitignored | `.gitignore` change | We ship subservices as part of the repo for declarative deployment, rather than treating them as runtime-only additions | Low — one line in .gitignore | Keep our .gitignore |
| `src/agi-doc.md` moved to `docs/developers/agi-reference.md` | File moved | Consolidated into our docs structure | **High if upstream updates agi-doc.md** | Merge upstream's content changes into `docs/agi-reference.md`. The old file is replaced with a pointer. |
| `src/README.md` replaced with pointer | Content moved to `docs/architecture.md` and `docs/developers/apps-and-subservices.md` | Consolidated | Medium if upstream updates | Merge content into our docs files |
| `examples/README.md` replaced with pointer | Content moved to `docs/developers/apps-and-subservices.md` and `docs/developers/frontend-api.md` | Consolidated | Medium if upstream updates | Merge content into our docs files |
| `README.md` slimmed down | Heavy content moved to docs/ | Upstream README is overloaded | Medium | Manual merge — keep our structure, integrate any new upstream content into the appropriate docs/ file |
| `README-DE.md` deleted | Stale German translation | Diverged from English, unmaintained | Low | Delete again if upstream re-adds |
| `Dockerfile` added | New file | Docker build support | None — new file | N/A |
| `src/subservice/Terminal/` added | New directory | Terminal subservice | None — new files | N/A |
| `src/web/WebTerminal/` added | New directory | Terminal wrapper app | None — new files | N/A |
| `src/web/img/subservice/` added | New directory | Subservice icons | None — new files | N/A |
| `AGENTS.md` added | New file | AI agent development guide | None — new file | N/A |
| `UPSTREAM-MERGE-GUIDE.md` added | This file | Merge documentation | None — new file | N/A |

## Content Mapping

When upstream updates documentation content, here's where it maps in our structure:

| Upstream file | Our location |
|---------------|-------------|
| `src/agi-doc.md` | `docs/developers/agi-reference.md` |
| `src/README.md` (dev notes) | `docs/architecture.md` + `docs/developers/apps-and-subservices.md` |
| `examples/README.md` | `docs/developers/apps-and-subservices.md` + `docs/developers/frontend-api.md` |
| `README.md` (startup flags) | `docs/admins/configuration.md` |
| `README.md` (install guides) | `docs/admins/deployment.md` |
| `README.md` (storage/file servers) | `docs/admins/configuration.md` + `docs/admins/deployment.md` |
| `docs/*` (marketing site) | Deleted — do not restore |
