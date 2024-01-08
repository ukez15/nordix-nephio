# Instructions for running Porch Demo

## Create the Kind clusters for management and edge1

Create the clusters:

```
kind create cluster --config=kind_managemnt_cluster.yaml
kind create cluster --config=kind_edge1_cluster.yaml
```

Output the kubectl config for the clusters:

```
kind get kubeconfig --name=management > ~/.kube/kind-management-config
kind get kubeconfig --name=edge1 > ~/.kube/kind-edge1-config
```

Toggle kubectl between the clusters:

```
export KUBECONFIG=~/.kube/kind-management-config
export KUBECONFIG=~/.kube/kind-edge1-config
```

## Install MetalLB on the management cluster

Install the MetalLB load balancer on the management cluster to expose services:
```
export KUBECONFIG=~/.kube/kind-management-config
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml
kubectl wait --namespace metallb-system \
                --for=condition=ready pod \
                --selector=component=controller \
                --timeout=90s
```

Check the subnet that is being used by the `kind` network in docker
```
docker network inspect kind | grep Subnet
                    "Subnet": "172.18.0.0/16",
                    "Subnet": "fc00:f853:ccd:e793::/64"
```
Edit the `metallb-conf.yaml` file and ensure the `spec.addresses` range is in the IPv4 subnet being used by the `kind` network in docker.

Apply the MetalLB configuration:
```
kubectl apply -f metallb-conf.yaml
```

## Deploy and set up gitea on the management cluster

Get the gitea kpt package:

```
export KUBECONFIG=~/.kube/kind-management-config
cd kpt_packages
kpt pkg get https://github.com/nephio-project/nephio-example-packages/tree/main/gitea
```

Comment out the preconfigured IP address from the `service-gitea-yaml` file in the gitea Kpt package:
```
11c11
<     metallb.universe.tf/loadBalancerIPs: 172.18.0.200
---
>     #    metallb.universe.tf/loadBalancerIPs: 172.18.0.200
```

Now render and apply the Gitea Kpt package:
```
kpt fn render gitea
kpt live init gitea # You only need to do this command once
kpt live apply gitea
```

Once the package is applied, all the gitea pods should come up and you should be able to reach the Gitea UI on the exposed IP Address/port of the gitea service.

```
kubectl get svc -n gitea gitea
NAME    TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)                       AGE
gitea   LoadBalancer   10.96.243.120   172.18.255.200   22:31305/TCP,3000:31102/TCP   10m
```
The UI is available at http://172.18.255.200:3000 in the example above.

To login to Gitea, use the credentials `nephio:secret`.

## Create repositories on Gitea for `management` and `edge1`

On the gitea UI, click the '+' opposite "Repositories" and fill in the form for both the `management` and `edge1` repositories. Use default values except for the following fields:

- Repository Name: "Management" or "edge1"
- Description: Something appropriate
 
 Now initialize both repos with an initial commit. Create a `repositories` directory locally and enter it.

 ```
 mkdir reposiories
 cd repositories
 ```

Initialize the `management` repo

```
git clone http://172.18.255.200:3000/nephio/management
cd management

touch README.md
git init
git checkout -b main
git config user.name nephio
git add README.md

git commit -m "first commit"
git remote remove origin
git remote add origin http://nephio:secret@172.18.255.200:3000/nephio/management.git
git remote -v
git push -u origin main
cd ..
 ```

Initialize the `edge1` repo

```
git clone http://172.18.255.200:3000/nephio/edge1
cd edge1

touch README.md
git init
git checkout -b main
git config user.name nephio
git add README.md

git commit -m "first commit"
git remote remove origin
git remote add origin http://nephio:secret@172.18.255.200:3000/nephio/edge1.git
git remote -v
git push -u origin main
cd ..
```

## Install Porch

We will use the Porch Kpt package from Nephio and we will update the kpt package to use the images generated for Porch in Nephio.
```
kpt pkg get https://github.com/nephio-project/nephio-example-packages/tree/main/porch-dev
cd porch-dev
```

Edit the `2-function-runner.yaml` file:
```
42c42
<           image: gcr.io/kpt-dev/porch-function-runner:v0.0.27
---
>           image: docker.io/nephio/porch-function-runner:latest
51c51
<               value: gcr.io/kpt-dev/porch-wrapper-server:v0.0.27
---
>               value: docker.io/nephio/porch-wrapper-server:latest
```

Edit the `3-porch-server.yaml` file:
```
50c50
<           image: gcr.io/kpt-dev/porch-server:v0.0.27
---
>           image: docker.io/nephio/porch-server:latest
```

Edit the `9-controllers.yaml.old `9-controllers.yaml` file:
```
45c45
<         image: gcr.io/kpt-dev/porch-controllers:v0.0.27
---
>         image: docker.io/nephio/porch-controllers:latest
```

## Connect the Gitea repositories to Porch

Create a demo namespace:

```
kubectl create namespace porch-demo
```

Create a secret for the Gitea credentials in the demo namespace:

```
kubectl create secret generic gitea \
    --namespace=porch-demo \
    --type=kubernetes.io/basic-auth \
    --from-literal=username=nephio \
    --from-literal=password=secret
```

Now, define the Gitea repositories in Porch:
```
kubectl apply -f porch-repositories.yaml
```

Check that the repositories have been correctly created:
```
kubectl get repositories -n porch-demo
NAME                  TYPE   CONTENT   DEPLOYMENT   READY   ADDRESS
edge1                 git    Package   true         True    http://172.18.255.200:3000/nephio/edge1.git
external-blueprints   git    Package   false        True    https://github.com/nephio-project/free5gc-packages.git
management            git    Package   false        True    http://172.18.255.200:3000/nephio/management.git
```

## Configure configsync on the workload cluster

Configsync is installed on the `edge1` cluster so that it syncs the contents of the `edge1` repository onto the `edge1` workload cluster. We will use the configsync package from Nephio.

```
export KUBECONFIG=~/.kube/kind-edge1-config
kpt pkg get https://github.com/nephio-project/nephio-example-packages/tree/main/configsync
kpt fn render configsync
kpt live init configsync
kpt live apply configsync
```

Now, we need to set up a Rootsync CR to synchronize the `edge1` repo:

```
kpt pkg get https://github.com/nephio-project/nephio-example-packages/tree/main/rootsync
```

Edit the `package-context.yaml` file to set the name of the cluster/repo we are syncing from/to:
```
9c9
<   name: example-rootsync
---
>   name: edge1
```

Render the package, this configures the `rootsync.yaml` file in the Kpt package:
```
kpt fn render rootsync
```

Edit the `rootsync.yaml` file to set the IP address of Gitea and to turn off authentication for accessing gitea:
```
11c11
<     repo: http://172.18.0.200:3000/nephio/example-cluster-name.git
---
>     repo: http://172.18.255.200:3000/nephio/edge1.git
13,15c13,16
<     auth: token
<     secretRef:
<       name: example-cluster-name-access-token-configsync
---
>     auth: none
> #    auth: token
> #    secretRef:
> #      name: edge1-access-token-configsync
```