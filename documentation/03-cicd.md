# CI/CD — ECR, Nexus, Argo CD

Entry point [`.gitlab-ci.yml`](../.gitlab-ci.yml) — stages, variables, includes; jobs in
[`ci-cd/`](../ci-cd).

**Never executed.** No AWS account, no Nexus, no GitLab project. The files parse as YAML but
have not been checked against GitLab's pipeline schema, which needs a real project.

## Jobs

| Stage | Job | File | |
|---|---|---|---|
| build | `build-image` | `ci-cd/build/mirror-image.yml` | Mirrors the upstream image into ECR under the commit SHA |
| test | `test-chart` | `ci-cd/test/chart.yml` | `helm lint` + `kubeconform` |
| test | `test-image` | `ci-cd/test/image.yml` | `trivy` scan |
| publish | `publish-chart` | `ci-cd/publish/chart.yml` | `helm package` → push `.tgz` to Nexus |

`ci-cd/common/aws-oidc.yml` holds `.aws-oidc`, the credential template the two ECR jobs extend.

```
build-image ──► test-image ──┐
                             ├──► publish-chart
test-chart ──────────────────┘
```

`test-chart` sets `needs: []` — it does not depend on the image, so it fails fast in parallel.

## Decisions

**The pipeline does not deploy.** Argo CD watches Nexus and reconciles into EKS. Still "deploy to
EKS", pull-based — and no job here holds any EKS permission. A push pipeline needs
cluster-mutating credentials sitting in a system that runs code from every merge request.

**"Build" is a mirror.** podinfo is a prebuilt public image, so a `docker build` would be theatre.
Mirroring into ECR is real work: deploys stop depending on a third party's registry, and the image
scanned is the image that ships. With real source this job builds instead — nothing downstream changes.

**The chart carries its own image tag.** `values.yaml` leaves `image.tag` empty and the template
falls back to `.Chart.AppVersion`, which `helm package --app-version "$IMAGE_TAG"` sets. No file
is rewritten, so chart metadata and running image cannot drift. Only `image.repository` is stamped
in, because it genuinely differs between local (ghcr.io) and AWS (ECR).

**Chart version `0.1.$CI_PIPELINE_IID`** — monotonic SemVer, so Argo can order releases. Build
metadata (`0.1.0+sha`) would not work: SemVer ignores it for precedence.

## AWS authentication

No AWS keys as CI variables. `.aws-oidc` requests a GitLab-signed OIDC token via `id_tokens` and
exchanges it through `sts assume-role-with-web-identity` for one-hour, job-scoped credentials.

The IAM trust policy pins the token's `sub` claim:

```
"token.gitlab.com:sub": "project_path:group/podinfo:ref_type:branch:ref:main"
```

Every GitLab project presents tokens from the same issuer, so without that condition any of them
could assume the role.

One role, `ECR_PUSH_ROLE_ARN`, scoped to this repository — there is no deploy role because there
is no deploy job. Nexus uses `NEXUS_USERNAME` / `NEXUS_PASSWORD` as masked variables; a static
credential scoped to one hosted repo is a small and rotatable blast radius.

## Trade-offs

**Argo tracks the latest chart, not a pinned version.** It works, but you can no longer tell what
is deployed by reading a repository, and rollback becomes a manual pin rather than a revert. The
alternative is CI committing the version bump into the Argo `Application`.

**This is the minimal pipeline.** A reusable template library is the right design for a team
running several services; cut because this repo runs one, so a second service means copies, and
copies drift. Also left out:

- No staging. One publish, one environment.
- No rollback path; that is Argo's problem now, and a manual one.
- No SBOM, signing or provenance. The scan checks known CVEs only.
