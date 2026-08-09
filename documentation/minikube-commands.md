# minikube command reference

Personal reference. Setup narrative: [01-minikube-setup.md](./01-minikube-setup.md)

## Cluster lifecycle

```sh
minikube start                    # start (uses saved driver config)
minikube stop                     # shut down, preserve state
minikube pause                    # freeze control plane, free CPU
minikube unpause
minikube delete                   # destroy the cluster
minikube status                   # host / kubelet / apiserver / kubeconfig health
minikube ip                       # node IP
minikube ssh                      # shell into the node
minikube logs                     # cluster logs, for debugging failed starts
minikube update-context           # repair kubeconfig if it drifts
minikube version
```

## Sizing

CPU and memory are fixed at creation time, so changing them means recreating:

```sh
minikube delete
minikube start --cpus=4 --memory=6g
```

## Profiles (multiple clusters)

```sh
minikube profile list
minikube start -p dev             # create/start a named cluster
minikube profile dev              # set the active profile
minikube delete -p dev
minikube delete --all
```

## Nodes

```sh
minikube node list
minikube node add
minikube node delete minikube-m02
minikube start --nodes=3          # multi-node at creation time
```

## Addons

```sh
minikube addons list
minikube addons enable ingress
minikube addons enable metrics-server
minikube addons enable registry
minikube addons disable ingress
minikube dashboard                # web UI (blocks; Ctrl-C to stop)
minikube dashboard --url          # print URL instead of opening a browser
```

## Images

The cluster has its own image store and cannot see images built by the host Docker:

```sh
minikube image ls                 # images available to the cluster
minikube image load myapp:latest  # push a host image into the node
minikube image build -t myapp:v1 .
eval $(minikube docker-env)       # point this shell's docker at the node
eval $(minikube docker-env -u)    # undo
```

Set `imagePullPolicy: IfNotPresent` in manifests when using locally loaded images.

## Services

```sh
minikube service <name>           # open a NodePort service in a browser
minikube service <name> --url     # print the URL only
minikube service list
minikube tunnel                   # LoadBalancer support; blocks, needs sudo
```

`minikube tunnel` must run in a separate terminal, or `LoadBalancer` services stay
`<pending>`.

## Config

```sh
minikube config view
minikube config set driver docker
minikube config set memory 6g
minikube config unset memory
```
