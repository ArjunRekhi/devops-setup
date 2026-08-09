# Helm section — what was done

Covers assignment tasks 3 (Helm packaging) and 4 (configuration and secrets), plus the
resilience extension. Chart lives at `application/charts/podinfo-app`.

Cluster setup: [01-minikube-setup.md](./01-minikube-setup.md)
Command reference: [helm-commands.md](./helm-commands.md)

## Approach

Written by hand rather than generated with `helm create`: the scaffolding ships a large
amount of unused boilerplate, and cleaning it up takes longer than writing the seven
templates the app actually needs.

The app is podinfo (`ghcr.io/stefanprodan/podinfo:6.14.1`) — a public image with real
`/healthz` and `/readyz` endpoints, so the probes are genuine rather than decorative. No
application code was written.

## What the chart contains

| Template | Purpose |
|---|---|
| `deployment.yaml` | Pod spec, probes, resources, config injection |
| `service.yaml` | ClusterIP on 9898 |
| `configmap.yaml` | Non-sensitive configuration |
| `secret.yaml` | Sensitive configuration, skipped when external |
| `serviceaccount.yaml` | Dedicated SA — the IRSA attachment point on EKS |
| `hpa.yaml` | CPU-based autoscaling |
| `pdb.yaml` | Disruption budget |
| `_helpers.tpl` | Five named templates |

Driven through `values.yaml`: image repository and tag, replica count, resources, probe
paths and timings, autoscaling bounds, disruption budget, and all config/secret values.
Every optional piece is behind a toggle — `autoscaling.enabled`,
`podDisruptionBudget.enabled`, `serviceAccount.create`, `probes.*.enabled`,
`secrets.existingSecret` — and the chart renders cleanly with each one off.

## Decisions worth explaining

**Image pinned to a tag, never `:latest`.** An unpinned tag makes a rollout
non-reproducible and `helm rollback` meaningless — the tag may point somewhere else by the
time you roll back. `values.yaml` leaves `image.tag` empty so it falls back to
`Chart.appVersion`: still pinned, and it lets CI stamp the tag at package time
([03-cicd.md](./03-cicd.md)).

**Config and secrets are separated by how they are consumed, not just where they live.**
Non-sensitive values come from a ConfigMap via `envFrom` — the whole map at once. The
secret is pulled key by key with `secretKeyRef`, so the Deployment documents exactly what
it needs and adding a key to the Secret does not silently widen what the container reads.

**`secrets.existingSecret` is the important half.** When set, the chart renders no Secret
and consumes one it does not own — the seam an external secrets manager plugs into, on EKS
External Secrets Operator syncing from AWS Secrets Manager. It keeps credentials out of
Helm values, which `helm get values` prints in plaintext.

**Checksum annotations.** Kubernetes does not restart pods when a ConfigMap changes.
Hashing the rendered content into a pod annotation makes a config edit an actual rollout.
Verified live: changing the UI colour produced a new checksum and rolled the pods. The
limitation is that it only reacts to changes made through Helm — a manual `kubectl edit cm`
restarts nothing and gets reverted on the next upgrade. Stakater Reloader is the answer if
out-of-band edits are a real scenario.

**Three probes, tuned differently on purpose.** The startup probe suspends the other two
for up to 60s, which lets liveness be aggressive without racing a slow start. Liveness is
slow and forgiving — restarts are expensive, and a hair-trigger probe turns a blip into a
restart storm. Readiness is fast and strict, because flipping it is cheap and reversible.

**CPU request with no CPU limit.** A limit enforces CFS quota and throttles the process
even when the node has idle cores; the request already guarantees a share and drives
scheduling. Memory is incompressible, so there `limit == request`.

**The HPA targets 75% CPU, not the usual 50%.** The request is 10m, so half of it is
measurement noise and the autoscaler would flap on it. Scale-up uses a 30s stabilization
window and scale-down 300s — deliberately asymmetric: being slow to add capacity costs
users latency, being slow to remove it costs a few cents, and eager scale-down causes
thrash when the load returns.

**`replicas` is omitted when the HPA is enabled.** Both write `spec.replicas`. If the chart
declares it, every `helm upgrade` resets the count and fights the autoscaler — and Helm's
three-way merge treats HPA scaling as drift to be corrected.

**PDB uses `maxUnavailable`, not `minAvailable`.** `minAvailable: 2` against 2 replicas
permits zero disruption, so a node drain hangs forever. `maxUnavailable: 1` stays correct
at any replica count.

**No PersistentVolumeClaim.** podinfo is stateless and `/data` is disposable cache. Real
state belongs in a database or object storage, not on a volume attached to a
horizontally-scaled Deployment.

**Resource names are fixed, not release-prefixed.** Objects are always `podinfo`,
`podinfo-config`, `podinfo-secret` — simpler to read and reference. The trade-off is that
two releases of this chart cannot coexist in one namespace: acceptable for a single-app
chart, and stated rather than discovered.

## Verified

Deployed to minikube (profile `podinfo-demo`, Kubernetes v1.35.1, Helm v4.2.3).

- `helm lint` passes; the chart renders under every value toggle.
- Release installed and upgraded to revision 2 via `helm upgrade --install --atomic --wait`.
- Two replicas running and ready.
- A ConfigMap change propagated end to end: values edit, new checksum, pod rollout.
- HPA reporting real metrics (`cpu: 10%/75%`), so autoscaling has live data to act on.

## Stress testing the autoscaler

Load is generated from inside the cluster so it goes through the Service and spreads across
replicas, rather than through a single port-forward:

```bash
kubectl -n podinfo run loadgen --image=busybox:1.36 --restart=Never --rm -it -- /bin/sh -c "for i in 1 2 3 4 5 6 7 8; do (while true; do wget -q -O- http://podinfo:9898/ >/dev/null 2>&1; done) & done; wait"
```

Watched from a second terminal:

```bash
kubectl -n podinfo get hpa podinfo -w
kubectl top pods -n podinfo
```

Ctrl-C stops the load and removes the pod.

The CPU request is 10m, so the 75% target is 7.5m and is easily exceeded. The HPA evaluates
every 15s against a 30s `scaleUp` window, so replicas climb within roughly a minute up to
`maxReplicas: 6`. Scale-down then holds for the full 300s `scaleDown` window before
stepping back to 2 — the configured anti-thrash behaviour, not a stall.

`TARGETS` showing `<unknown>` means metrics-server has not scraped yet; it needs a minute
or two after pods start.

## Out of scope here

CI/CD is covered separately in [03-cicd.md](./03-cicd.md). The rest is not implemented
anywhere: the brief asks for one or two optional extensions, Resilience and CI/CD are the
two chosen, and the others were left out rather than half-built.

- **Ingress and TLS.** Access is through `kubectl port-forward`, which the brief explicitly
  allows. On macOS with the Docker driver the node IP is not routable, so a local Ingress
  would have needed `minikube tunnel` running under sudo to demonstrate anything.
- **Database integration.** podinfo has no PostgreSQL client — only a Redis cache backend —
  so "wiring the app to it" would have meant an initContainer running `psql` to prove
  connectivity while the app itself stayed unaware. That demonstrates the Secret plumbing,
  not an application talking to a database.
- **Pod and container security context.** Not a one-line addition: the podinfo image
  declares a non-root but *named* user (`app`, dynamic UID from `adduser -S`), and setting
  `runAsNonRoot` without a numeric `runAsUser` makes the kubelet refuse the pod outright.
  Getting it right means pinning the UID the image actually resolves to.
