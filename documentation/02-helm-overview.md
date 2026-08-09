# Helm section — what was done

Covers assignment tasks 3 (Helm packaging) and 4 (configuration and secrets), plus the
resilience extension. Chart lives at `kubernetes-application/charts/podinfo-app`.

Cluster setup: [01-minikube-setup.md](./01-minikube-setup.md)
Command reference: [helm-commands.md](./helm-commands.md)

## Approach

The app is podinfo (`ghcr.io/stefanprodan/podinfo:6.14.1`) — a public image with real
`/healthz` and `/readyz` endpoints, so the probes are genuine rather than decorative. No application code was written.

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

**Checksum annotations.** Kubernetes does not restart pods when a ConfigMap changes.
Hashing the rendered content into a pod annotation makes a config edit an actual rollout.
Verified live: changing the UI colour produced a new checksum and rolled the pods. The
limitation is that it only reacts to changes made through Helm — a manual `kubectl edit cm` restarts nothing and gets reverted on the next upgrade.

**Three probes, tuned differently on purpose.** The startup probe suspends the other two
for up to 60s, which lets liveness be aggressive without racing a slow start. Liveness is
slow and forgiving — restarts are expensive, and a hair-trigger probe turns a blip into a
restart storm. Readiness is fast and strict, because flipping it is cheap and reversible.

**CPU request with no CPU limit.** A limit enforces CFS quota and throttles the process
even when the node has idle cores; the request already guarantees a share and drives
scheduling. Memory is incompressible, so there `limit == request`.

**The HPA targets 75% CPU, not the usual 50%.** The request is 10m, so half of it is
measurement noise and the autoscaler would flap on it. Scale-up uses a 30s stabilization
window and scale-down 120s — deliberately asymmetric: being slow to add capacity costs
users latency, being slow to remove it costs a few cents, and eager scale-down causes
thrash when the load returns. Kubernetes defaults scale-down to 300s; 120s keeps the
asymmetry while letting the demo finish, and production would raise it again.

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
`maxReplicas: 6`. Stepping back to 2 takes about four minutes from the load stopping —
metrics-server needs a minute or two to report the drop, and only then does the 120s
`scaleDown` window run. Measured at 268s. That is the configured anti-thrash behaviour
plus scrape lag, not a stall.

`TARGETS` showing `<unknown>` means metrics-server has not scraped yet; it needs a minute
or two after pods start.
