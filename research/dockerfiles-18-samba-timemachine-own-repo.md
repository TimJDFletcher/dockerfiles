# samba-timemachine in its own repo: research for #18

Date: 2026-11-15. Ticket: [#18](https://github.com/TimJDFletcher/dockerfiles/issues/18)
"Migrate samba-timemachine to a separate repo". Facts about this repo are at
`origin/main` 2265c9b unless a line says otherwise.

## The question

What does a separate samba-timemachine repo look like: what moves, how its
history comes across, its name and tracker, its tags, its CI, release and
Dependabot on GitHub, its registry, and which consumers change.

The owner's decisions on 2026-11-15, in his words: "#18 wayfinder"; on
[#20](https://github.com/TimJDFletcher/dockerfiles/issues/20),
[#21](https://github.com/TimJDFletcher/dockerfiles/issues/21) and
[#22](https://github.com/TimJDFletcher/dockerfiles/issues/22): "fold that
into 18 if we move to a new repo we'll do CI via github properly"; on
[#30](https://github.com/TimJDFletcher/dockerfiles/issues/30): "fold that
into 24 and 18". So the new repo's CI, release and Dependabot are in scope
here. What happens to the images left in this repo is
[#23](https://github.com/TimJDFletcher/dockerfiles/issues/23)'s business.

## Summary

- The move is mostly mechanical. `samba-timemachine/` has 26 files and
  only two real ties to the rest of this repo: the `../goss` build and the
  root docs. Upstream goss now ships what `goss/` was built to replace, so
  the move is the natural point to drop `goss/` rather than carry it.
- The real decisions are about continuity: whether the 364 commits and 51
  pushed `timemachine-v*` tags come across, and whether the
  `timjdfletcher/samba-timemachine` Docker Hub name (about 394k pulls)
  keeps getting new tags once publishing moves to GHCR.
- One thing to fix before any extraction: the `timemachine-v4.0` tag, which
  both backup hosts run, exists only in a local checkout. Its commit is on
  no branch and not on GitHub (see "Tags").

## What exists today

- `samba-timemachine/`: 26 tracked files (Dockerfile, `run`, `entrypoint`,
  `scripts/`, `goss/tests/`, `grafana/`, `docs/Container.md`, compose files,
  `AGENTS.md`, `README.md`, `.trivyignore`).
- History: 304 commits touch `samba-timemachine/` (`git rev-list --count
  origin/main -- samba-timemachine`), plus 60 earlier ones under `samba/`,
  which commit 142644c (2018-07-01, "Rename directory to match docker hub")
  renamed to `samba-timemachine/`. The repo has 505 commits in all.
- Ties to the rest of the repo:
  - `samba-timemachine/Dockerfile:2-3`: "Build first: cd ../goss && ./run
    build" and `ARG GOSS_IMAGE="timjdfletcher/goss:latest"`, used in
    `FROM ${GOSS_IMAGE} AS goss`.
  - `samba-timemachine/run:25` builds `../goss` when the goss image is
    missing; `release()` (`run:297-328`) builds against
    `timjdfletcher/goss:latest` from Docker Hub.
  - `samba-timemachine/AGENTS.md:10,15-23,88,119` and `README.md:256` point
    at `../goss`.
  - Root `AGENTS.md:14,87-89,126,175-176,212,226,231`, `README.md:9,40,49-59`,
    `.cursorrules`, `.agents/skills/dockerfiles-repo-upgrade/SKILL.md:37,39,62,76,86`
    and `skills/goss/README.md:102-104` describe samba-timemachine.
  - `TODO/01..08-*.md` are eight samba-timemachine tickets kept as files at
    the repo root, outside `samba-timemachine/`.
- `goss/` (3 files) builds goss v0.4.9 from source with `golang.org/x/crypto`
  bumped (`goss/Dockerfile`). Root `AGENTS.md:126` lists samba-timemachine as
  its only user.
- No `.github/`, no `Makefile`, no `.tool-versions`, no `trivy.yaml`.
- The Gitea copy `tim/dockerfiles` is a pull mirror of this repo (mirror
  flag true, interval 8h, read from the Gitea API today). Its tracker holds
  two open samba-timemachine tickets, Gitea `tim/dockerfiles` #1 and #2
  (REDACTED).
  These are not GitHub #1 and #2, which are closed and unrelated.
- No repo named `samba-timemachine` exists on GitHub (`gh repo view
  TimJDFletcher/samba-timemachine`: not found) or on the owner's Gitea.

## What moves

| Item | Moves? | Notes |
| --- | --- | --- |
| `samba-timemachine/` | yes, to the repo root | The `run` script, Dockerfile and compose files assume their own directory, so a root layout works unchanged once `../goss` is gone. |
| `goss/` | no (recommended) | Upstream goss v0.4.10 (2026-07-26) is out. It is published as `ghcr.io/goss-org/goss:v0.4.10` (the manifest answers 200 to an anonymous pull today), and as release binaries with a `goss_0.4.10_SHA256SUMS` file ([releases](https://github.com/goss-org/goss/releases/tag/v0.4.10)). `TODO/08` asks for exactly this switch. Carrying `goss/` means a second image, a Go build in CI and a second tag series in the new repo. PR #19 made this switch and was closed unmerged on 2026-10-10 with no comment, so this needs the owner's yes. |
| `TODO/01..08` | yes | Every one is about samba-timemachine (`Source:` line 5 in each). They become issues in the new tracker, or stay as files there. `TODO/08` is closed by the goss switch. |
| Open GitHub issues #18, #20, #21, #22, and the samba part of #30 | yes | GitHub can transfer an issue to another repo owned by the same account, keeping comments and assignees; labels and milestones carry only if one with the same name exists in the target ([docs](https://docs.github.com/en/issues/tracking-your-work-with-issues/administering-issues/transferring-an-issue-to-another-repository)). #30's other images stay with #24 here. |
| Gitea `tim/dockerfiles` #1 and #2 | yes, by hand | A Gitea issue cannot be transferred to GitHub; recreate them in a tracker that is not public, and close the Gitea ones with a link. |
| `grafana/timemachine-dashboard.json` | yes | homelab-ansible vendors it from a blob permalink at bcd0ff8 (`roles/monitoring_stack/files/dashboards/README.md:170`), which keeps working as long as this repo keeps its history. |
| Docs | yes | `samba-timemachine/README.md`, `AGENTS.md`, `docs/Container.md`. The root-level samba sections of `AGENTS.md` (`:89` onward) fold into the new repo's `AGENTS.md`. |

## History

Three ways to bring it across:

1. **Extract with `git filter-repo`.** `--path samba/ --path
   samba-timemachine/` plus `--path-rename samba-timemachine/:` and
   `--path-rename samba/:` keeps all 364 commits with the files at the root.
   `--subdirectory-filter` alone is "Equivalent to using `--path
   <directory>/ --path-rename <directory>/:`" and would drop the 60
   pre-rename commits. Add `--path TODO/` to keep the tickets' history.
   filter-repo rewrites tags along with the commits they point at, and
   `--tag-rename` can change their prefix ("--tag-rename foo:bar will rename
   tag foo-1.2.3 to bar-1.2.3; either <old> or <new> can be empty"). It
   wants a fresh clone ([git-filter-repo
   manual](https://github.com/newren/git-filter-repo/blob/main/Documentation/git-filter-repo.txt)).
   It is not installed on this machine.
2. **`git subtree split --prefix=samba-timemachine`.** It builds "a new,
   synthetic project history from the history of the <prefix> subtree ...
   suitable for export as a separate git repository"
   ([git-subtree](https://github.com/git/git/blob/master/contrib/subtree/git-subtree.adoc)).
   Run on a scratch clone today it gives 304 commits: the pre-2018 `samba/`
   history is lost, and it carries no tags.
3. **Copy with provenance.** One import commit whose message names this
   repo and the source SHA; the old history stays here and is reached by
   permalink. This is how estate brings material in from other repos. It is
   the simplest, but blame and `git log` in the new repo start on the
   import date, and the release tags stay here.

Either way, the rewritten commits get new SHAs. Existing permalinks into
this repo (the dashboard source line above, issue comments) keep working
only because this repo is left in place, not deleted or rewritten.

## Name, hosting, tracker

- **Name.** `TimJDFletcher/samba-timemachine` matches the image name, the
  `IMAGE_NAME` in `run:4`, and the Docker Hub repo. No other candidate
  appears in the record.
- **Hosting.** GitHub, public. The owner's 2026-11-15 decision ("we'll do CI
  via github properly") and the existing users (this repo has 15 stars and
  4 forks) point there. Standard GitHub-hosted runners, the arm64
  `ubuntu-24.04-arm` included, are "free and unlimited on public
  repositories" ([runner
  reference](https://docs.github.com/en/actions/reference/runners/github-hosted-runners)).
- **Tracker.** GitHub Issues on the new repo, as this repo does
  (`docs/agents/issue-tracker.md`).
- **Gitea mirror.** A pull mirror on the owner's Gitea, as this repo has.
  Gitea mirrors "branches, tags, and commits", and a pull mirror can be set
  up only when the repo is created on Gitea, not added to an existing one
  ([Gitea docs](https://docs.gitea.com/usage/repo-mirror)). The mirror's
  tracker should stay unused, which is what went wrong with `tim/dockerfiles`
  #1 and #2.

## Tags

- GitHub holds 51 `timemachine-v*` tags (`git ls-remote`), from
  `timemachine-v1.0` to `timemachine-v3.9.1`. The local checkout has 52,
  65 tags in all across projects.
- **`timemachine-v4.0` is local only.** It is a lightweight tag on 1d31057
  ("bump Debian base to trixie-20261005-slim", 2026-10-14), which is on no
  branch and not on GitHub. It differs from `origin/main` in
  `samba-timemachine/Dockerfile`, `.trivyignore` (11 lines) and `AGENTS.md`.
  Docker Hub has `timemachine-v4.0` (pushed 2026-10-13T23:17Z), and
  homelab-ansible pins it (`inventory/group_vars/backup_hosts/main.yml:23`).
  The source of the running release exists in one checkout. It should be
  pushed (tag and a branch or PR for the commit) before any extraction, or
  the extraction should start from that checkout.
- **Prefix.** In a repo of its own the `timemachine-` prefix no longer
  separates projects, so the
  [#20](https://github.com/TimJDFletcher/dockerfiles/issues/20) failure (two
  projects' tags on one commit, `git describe` picking the wrong one) cannot
  happen. Choices:
  - keep `timemachine-v<version>` for git tags and image tags: no break for
    the homelab-ansible pin, Docker Hub tags, or anyone pinning
    `timemachine-v*`;
  - switch to `v<version>` from the next release, keeping old tags as they
    are: `filter-repo --tag-rename timemachine-v:v` could also rename the
    old ones, but the image tags already pulled by users cannot be renamed.
- Root `AGENTS.md:43,180` and `README.md:40` say `<project>-v` /
  `samba-timemachine-v1.2.3`, which no tag uses; the new repo writes the
  scheme once.
- What #20 still adds in a repo of its own: fetch first and check `main`
  is current before tagging. The release workflow takes its tag from
  `github.ref_name`, not `git describe`, so the multi-tag guard is no
  longer needed.

## CI: `make lint test` on every push

From [#21](https://github.com/TimJDFletcher/dockerfiles/issues/21) and
estate ADR 0003, applied to the new repo. The template is infra's:
`.github/workflows/ci.yml` (on `push`, no path filter, top-level
`permissions: contents: read`, `actions/checkout` pinned by SHA with
`persist-credentials: false`, then a local `setup-tools` composite action
and `make lint test`), and infra's `Makefile` `tools` target, which installs
asdf plugins pinned by commit and the versions in `.tool-versions`.

- `make lint`: shellcheck on `run`, `entrypoint` and `scripts/*.sh`;
  actionlint on the workflows.
- `make test`: `./run test`, which builds the image and runs the goss
  suites. #21 also asks for `./run test` to accept a supplied image, which
  the release needs.
- `trivy.yaml` holding today's inline flags (`run:251-259`: HIGH and
  CRITICAL, ignore unfixed, exit code 1, `.trivyignore`).
- Goss: with `goss/` gone, the Dockerfile takes
  `FROM ghcr.io/goss-org/goss:v0.4.10@sha256:<digest> AS goss`. CI then
  builds one image per run. The alternative, a checksummed download of the
  release binary, is what `TODO/08` describes; either works, the image
  form keeps today's `COPY --from=goss` shape.
- `copyToTestHost` (`run:9`, `TESTHOST="REDACTED"`) reaches a live host
  and stays out of `make test`.

## Release: build once, test, scan, promote

From [#22](https://github.com/TimJDFletcher/dockerfiles/issues/22),
unchanged in shape:

1. A pushed `timemachine-v*` (or `v*`) tag triggers it.
2. Each architecture is built once into an OCI archive on its native
   runner (`ubuntu-latest`, `ubuntu-24.04-arm`) and passed on as a workflow
   artifact.
3. Each archive is tested with `./run test` on the supplied image, and
   scanned with trivy in a job holding no publish permission.
4. Publish only after both pass: `skopeo copy --preserve-digests`
   ("Preserve the digests during copying. Fail if the digest cannot be
   preserved", [skopeo-copy](https://github.com/containers/skopeo/blob/main/docs/skopeo-copy.1.md)),
   then join the two into one multi-arch tag plus `latest`. How to join
   without changing the per-arch digests (for example `docker buildx
   imagetools create`) is an implementation detail I did not test.
5. Re-fetch the manifest and check the digest equals the tested one.
6. Create the GitHub release named after the tag, with generated notes
   from the previous tag (`previous_tag_name` in the [release notes
   API](https://docs.github.com/en/rest/releases/releases#generate-release-notes-content-for-a-release)
   sets the range explicitly).

Permissions: top-level `contents: read`; the publish job alone adds
`packages: write` (GHCR) and `contents: write` (the release). The ticket's
`id-token: write` was for Docker Hub OIDC; it is needed again only if the
owner wants GitHub artifact attestations.

"Only the owner pushes release tags" can be made real with a tag ruleset:
"Restrict creations: ... only users with bypass permissions can create
branches or tags whose name matches the pattern you specify" ([available
rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets)).
The rulesets API answers on this public repo (`gh api
repos/TimJDFletcher/dockerfiles/rulesets` returns `[]`, no ruleset set), so
the feature is there on the owner's plan.

## Registry

- **The record.** ADR 0003 says "publishes to Docker Hub only" and waits on
  Docker Hub OIDC (infra#147). The owner on infra#147, 2026-10-12: "i'm not
  going to pay dockerhub $15 a month for a team account so we can use OIDC.
  Find alteratives and what the community says, I'm thinking to move to GCP
  and Gtihub (dual push)". The later research comment there recommends GHCR
  only and the closing comment says "owner agreed 2026-10-16"; both are
  agent-written, so they are leads, not the owner's word. ADR 0003 and
  estate `docs/knowledge/ci-cd.md` still say Docker Hub and need an
  amendment whichever way this goes.
- **GHCR.** The workflow pushes with its own `GITHUB_TOKEN`; no stored
  secret ([Container registry
  docs](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)).
  "Container image storage and bandwidth for the Container registry is
  currently free" and "GitHub Packages usage is free for public packages"
  ([billing](https://docs.github.com/en/billing/concepts/product-billing/github-packages)).
  The package lives under the user (`ghcr.io/timjdfletcher/samba-timemachine`),
  so its name does not depend on the repo name. Gotchas from the docs: a new
  package starts private, and "Once you make a package public, you cannot
  make it private again"; link it with `LABEL
  org.opencontainers.image.source=https://github.com/TimJDFletcher/samba-timemachine`
  before the first push so it inherits the repo's access, or grant the repo
  Actions access in the package settings; a multi-arch image's description
  comes from the `org.opencontainers.image.description` manifest annotation
  ([access and
  visibility](https://docs.github.com/en/packages/learn-github-packages/configuring-a-packages-access-control-and-visibility)).
  The throwaway-tag acceptance test in #22 should not push to the public
  package.
- **Docker Hub continuity.** The Docker Hub API today: 393,995 pulls, 11
  stars, last push 2026-10-13 (`timemachine-v4.0` and `latest`). Docker
  Hub's pull limits fall on the puller, 100 pulls per 6 hours per IPv4
  address unauthenticated ([usage
  limits](https://docs.docker.com/docker-hub/usage/pulls/)). I found no way
  to redirect a Docker Hub repo to another registry. So existing users keep
  the tags they have, and get new ones only if someone keeps pushing there.
  Keeping a CI push to Docker Hub means a stored token, and "A PAT has one
  repository permission for every repository the account can access"
  ([access tokens](https://docs.docker.com/security/access-tokens/)): it
  could push to every `timjdfletcher/*` image. Freezing means one last
  manual note in the Docker Hub description and README pointing at GHCR.
- **GCP Artifact Registry** (the owner's "dual push" idea). The infra#147
  research priced public egress at about $30/month with no hard cap and
  noted infra's GitHub OIDC pool accepts only the infra repo. I did not
  re-verify those numbers; they are a lead.

## Dependabot

`.github/dependabot.yml` in the new repo, weekly, no automerge. Ecosystem
names from the [supported ecosystems
table](https://docs.github.com/en/code-security/dependabot/ecosystems-supported-by-dependabot/supported-ecosystems-and-repositories):

- `github-actions`, `directories: ["/", "/.github/actions/*"]`, grouped, as
  infra does. `directories` "supports globbing and the wildcard character
  `*`" ([options
  reference](https://docs.github.com/en/code-security/dependabot/working-with-dependabot/dependabot-options-reference)).
- `docker` for `/`. Today's Dockerfile has no literal `FROM` tag:
  `FROM ${GOSS_IMAGE}` and `FROM debian:${DEBIAN_VERSION}`, which #30 notes
  Dependabot does not follow. It becomes useful only if the pins move into
  the `FROM` lines, which is #24's idea applied here: `FROM
  ghcr.io/goss-org/goss:v0.4.10@sha256:…` and `FROM
  debian:trixie-…-slim@sha256:…`. Docker version updates are supported;
  Docker security updates are not (same table).
- `docker-compose` for `/`: the compose files reference the image itself
  (`docker-compose.yml:29`, `${IMAGE_VERSION:-latest}`), so this gives no
  PRs. Leave it out or say so.
- No `bundler`: samba-timemachine has no Gemfile.
- `SAMBA_VERSION` (an apt pin in an `ARG`) stays a manual bump.
- Any branch name but `dependabot` (infra `AGENTS.md`: Dependabot fails
  while a branch of that name exists).

## Consumers to update

- homelab-ansible (Gitea):
  - `roles/timemachine_stack/templates/docker-compose.yml.j2:36`:
    `image: timjdfletcher/samba-timemachine:{{ timemachine_image_tag }}`.
    Changes to `ghcr.io/timjdfletcher/...` only if the registry changes.
  - `inventory/group_vars/backup_hosts/main.yml:23`: `timemachine_image_tag:
    timemachine-v4.0`. Changes only if the tag prefix changes, at the first
    release from the new repo. Its comment at `:21` cites "TimJDFletcher/dockerfiles
    PR 29", which stays true.
  - `roles/timemachine_stack/meta/argument_specs.yml:46` and `README.md:10`
    name the Docker Hub image.
  - homelab-ansible's Renovate runs `custom.regex` only (`renovate.json`),
    and the tag pin has no `renovate:` annotation, so bumps stay manual
    whichever registry is used.
  - The hosts pull anonymously; a public GHCR package needs no credential.
- estate: `CONTEXT-MAP.md:26-28` ("e.g. `samba-timemachine`" under
  dockerfiles) gains a row for the new repo; ADR 0003's dockerfiles section
  and `docs/knowledge/ci-cd.md` rows `:73,85,145-147,158-173,260-263` move to
  the new repo and to the registry decision.
- agent-skills: `repo-specific/dockerfiles-repo-upgrade/SKILL.md` (build
  goss before samba-timemachine) and `repo-specific/goss/README.md:104`.
  (This repo carries copies under `.agents/skills/` and `skills/`.)
- vm-agent-harness ADR 0001 mentions where the `TODO/` tickets came from;
  it is history and stays as is.

## What dockerfiles keeps

- Every other image, and its history: the samba-timemachine commits and
  the 51 `timemachine-v*` tags stay here. Deleting them would break the
  permalinks and anyone building an old tag from source.
- `samba-timemachine/` is removed in one commit naming the new repo and the
  SHA it was extracted at. The root `README.md:9` row and `AGENTS.md:14`
  row become a pointer to the new repo.
- `goss/`: with samba-timemachine gone it has no user in this repo. Whether
  it is retired is #23's or #24's call, not this ticket's.
- #30's Dependabot for the remaining images, folded into #24.
- The Gitea pull mirror `tim/dockerfiles` carries on as is.

## Candidate destinations

**A. Full history, GHCR only.** New public `TimJDFletcher/samba-timemachine`
extracted with `git filter-repo` (364 commits, `samba/` and
`samba-timemachine/` at the root, tags kept as `timemachine-v*`), upstream
goss by digest, `goss/` left behind. CI, release and Dependabot as above,
publishing to GHCR with `GITHUB_TOKEN`. Docker Hub frozen at
`timemachine-v4.0` with a "moved" note. Issues transferred; Gitea pull
mirror. homelab-ansible changes its image line once.

**B. Clean start, GHCR only.** Same repo and pipeline, but one import
commit with provenance; history and old tags stay in dockerfiles. Less to
get right (no filter-repo run, no tag rewriting); `git log` and blame in
the new repo start in 2026. The first release from the new repo can switch
to `v*` tags without renaming anything.

**C. Full history, GHCR plus Docker Hub.** As A, but the publish job also
pushes the same digests to Docker Hub with a stored PAT (a GitHub Actions
secret, account-wide write). Docker Hub users keep getting releases; the
cost is the stored secret this design set out to avoid, and two registries
to verify.

## Questions only the owner can answer

1. Which destination: A, B or C? In particular, does Docker Hub keep
   getting new releases (C), or freeze with a pointer to GHCR (A, B)?
2. Is GHCR the registry, as the agent-written infra#147 comments say you
   agreed on 2026-10-16, or still GCP plus GitHub dual push?
3. Upstream goss by digest and `goss/` left behind? PR #19 did this and you
   closed it unmerged on 2026-10-10 with no comment: was something wrong
   with it?
4. Tag prefix: keep `timemachine-v*`, or `v*` from the next release?
5. The `timemachine-v4.0` commit (1d31057) is only in a local checkout:
   push it here first, or extract from that checkout?
6. Repo name `samba-timemachine`, public, on GitHub with a Gitea pull
   mirror: yes?
