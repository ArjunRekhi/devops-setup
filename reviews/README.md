# Review findings

Output of four independent section reviews run before submission. One file per section.

**These files are working notes, not part of the submission.** Delete the folder (or add
`reviews/` to `.gitignore`) before sending the repo.

| File | Section | Findings |
|---|---|---|
| [01-cluster.md](./01-cluster.md) | `cluster/`, minikube docs | 5 |
| [02-helm.md](./02-helm.md) | `application/`, chart + scripts | 11 |
| [03-cicd.md](./03-cicd.md) | `.gitlab-ci.yml`, `ci-cd/` | 7 |
| [04-aws-infra.md](./04-aws-infra.md) | `cloud-setup/` | 12 + hardening list |

## How to use

Each finding has a **Decision:** line. Write `apply`, `skip`, or a note. I'll action whatever
is marked `apply`.

Findings marked **[verified]** were re-checked directly against the files rather than taken
from the reviewer's report. Findings marked **[unverified]** depend on upstream module
behaviour or AWS service limits that were not confirmed — treat those as leads.

## Cross-cutting

Two things appear in more than one review and are worth deciding once:

- **Both command-reference docs** (`minikube-commands.md`, `helm-commands.md`) were
  independently judged mostly padding. Same decision applies to both.
- **`NOTES.md` Q3 prefers the CSI Driver**, but `cloud-setup/` implements External Secrets
  Operator — and the AWS review found that ESO implementation to be the strongest part of the
  infrastructure. The submission currently argues for one approach and ships the other.

## Already applied

Documentation trims were made in place (prose only, no factual claim added, removed or
altered). Every trim is listed per file.
