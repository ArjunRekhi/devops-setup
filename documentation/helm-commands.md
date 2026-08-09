# Helm commands

Release `podinfo`, namespace `podinfo`, chart at `application/charts/podinfo-app`.

## Before deploying (no cluster needed)

```bash
helm lint application/charts/podinfo-app
helm template podinfo application/charts/podinfo-app -n podinfo
helm template podinfo application/charts/podinfo-app -n podinfo --show-only templates/deployment.yaml
helm template podinfo application/charts/podinfo-app -n podinfo --set autoscaling.enabled=false
```

## Deploy

```bash
helm upgrade --install podinfo application/charts/podinfo-app -n podinfo --create-namespace --atomic --wait --timeout 5m
helm upgrade --install podinfo application/charts/podinfo-app -n podinfo -f application/charts/values-secret.yaml --atomic --wait
helm install podinfo application/charts/podinfo-app -n podinfo --dry-run --debug
```

`--install` makes it idempotent — same command for first install and every upgrade.
`--wait` blocks until pods are actually ready rather than merely accepted by the API server.
`--atomic` implies `--wait` and rolls back automatically on failure, so a bad deploy never
leaves a half-applied release. Drop `--atomic` when debugging, or the failing pods are
deleted before you can inspect them.

## Inspect

```bash
helm list -n podinfo
helm status podinfo -n podinfo
helm history podinfo -n podinfo
helm get manifest podinfo -n podinfo
helm get values podinfo -n podinfo
helm get values podinfo -n podinfo --all
```

`helm get manifest` is the useful one: it prints what the live release actually applied, so
you can compare intent against reality.

`helm get values --all` prints overrides merged with chart defaults — including anything
passed via `-f values-secret.yaml`, in plaintext. That is the reason the chart supports
`secrets.existingSecret`.

## Verify a config change took effect

```bash
helm get manifest podinfo -n podinfo | grep -E 'checksum/config|PODINFO_UI_COLOR'
```

The `checksum/config` annotation changes whenever the rendered ConfigMap changes, which is
what forces a pod rollout. It only reacts to changes made through Helm — a manual
`kubectl edit cm` will not restart anything.

## Rollback and remove

```bash
helm rollback podinfo 1 -n podinfo --wait
helm uninstall podinfo -n podinfo
```

## Package

```bash
helm package application/charts/podinfo-app
```

## Diff plugin

```bash
helm plugin install https://github.com/databus23/helm-diff
helm diff upgrade podinfo application/charts/podinfo-app -n podinfo
```

Previews exactly what an upgrade would change before you run it.

## Note

Installed Helm is v4. `helm status` lists resources by default; the older
`--show-resources` flag no longer exists.
