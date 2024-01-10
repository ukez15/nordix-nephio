# Porch Tutorial

This tutorial is a guide to setting up your local environment for Porch development. Users should be very comfortable with using with `git`, `docker`, and `kubernetes` as well as developing in the `go` language.

# Table of Contents
1. [Prerequisites](#Prerequisites)
2. [Set up your local environment for Porch](#Set-up-your-local-environment-for-Porch)
3. [Clone Porch and apply the Porch CRDs](#Clone-Porch-and-apply-the-Porch-CRDs)

See also [the Nephio Learning Resource](https://github.com/nephio-project/docs/blob/main/learning.md) page for background help and information.

## Prerequisites

The tutorial can be executed on a Linux VM or directly on a laptop. It has been verified to execute on a Macbook Pro M1 machine and an Ubuntu 20.04 VM.

The following software should be installed prior to running through the tutorial:
1. [git](https://git-scm.com/)
2. [Docker](https://www.docker.com/get-started/)
3. [kubectl](https://kubernetes.io/docs/reference/kubectl/)
4. [kind](https://kind.sigs.k8s.io/)
5. [kpt](https://github.com/kptdev/kpt)
6. [The go programming language](https://go.dev/)
7. [Visual Studio Code](https://code.visualstudio.com/download)
8. [VS Code extensions for go](https://code.visualstudio.com/docs/languages/go)
9. [yq yaml query utility](https://mikefarah.gitbook.io/yq/)

## Set up your local environment for Porch

You need to install `kind` clusters, `gitea`, and other components and configure those components in a certain manner to work with Porch. To do this follow **steps 1 to 6** of the [Starting with Porch](#../starting-with-porch/README.md) tutorial.

## Clone Porch and apply the Porch CRDs

Clone [Porch porch from Github](https://github.com/nephio-project/porch.git) onto your local environment using whatever cloning process for development your organization recommends. Here, we assume Porch is cloned into a directory called `porch`.

Once Porch is cloned, we need to apply the Porch CRDs into the management cluster. The CRDs are in the directory `controllers/config/crd/bases`.

```
cd porch

kubectl apply -f controllers/config/crd/bases 
customresourcedefinition.apiextensions.k8s.io/fleetmembershipbindings.config.porch.kpt.dev created
customresourcedefinition.apiextensions.k8s.io/fleetmemberships.config.porch.kpt.dev created
customresourcedefinition.apiextensions.k8s.io/fleetscopes.config.porch.kpt.dev created
customresourcedefinition.apiextensions.k8s.io/fleetsyncs.config.porch.kpt.dev created
customresourcedefinition.apiextensions.k8s.io/packagevariants.config.porch.kpt.dev created
customresourcedefinition.apiextensions.k8s.io/packagevariantsets.config.porch.kpt.dev created
customresourcedefinition.apiextensions.k8s.io/remoterootsyncsets.config.porch.kpt.dev created
customresourcedefinition.apiextensions.k8s.io/rootsyncdeployments.config.porch.kpt.dev created
customresourcedefinition.apiextensions.k8s.io/rootsyncrollouts.config.porch.kpt.dev created
customresourcedefinition.apiextensions.k8s.io/rootsyncsets.config.porch.kpt.dev created
customresourcedefinition.apiextensions.k8s.io/workloadidentitybindings.config.porch.kpt.dev created
```

Check that the Package Variant Set and package Variant CRDs are defined.

```
kubectl get crd packagevariantsets.config.porch.kpt.dev 
NAME                                      CREATED AT
packagevariantsets.config.porch.kpt.dev   2024-01-10T16:15:11Z

kubectl get crd packagevariants.config.porch.kpt.dev
NAME                                   CREATED AT
packagevariants.config.porch.kpt.dev   2024-01-10T16:15:11Z
```

We also need to apply the Repository and Function CRDs. These CRDs are in the directory `api/porchconfig/v1alpha1`.

```
kubectl apply -f api/porchconfig/v1alpha1/config.porch.kpt.dev_repositories.yaml 
customresourcedefinition.apiextensions.k8s.io/repositories.config.porch.kpt.dev created

kubectl get crd repositories.config.porch.kpt.dev
NAME                                CREATED AT
repositories.config.porch.kpt.dev   2024-01-10T16:40:21Z

kubectl apply -f api/porchconfig/v1alpha1/config.porch.kpt.dev_functions.yaml   
customresourcedefinition.apiextensions.k8s.io/functions.config.porch.kpt.dev created

kubectl get crd functions.config.porch.kpt.dev
NAME                             CREATED AT
functions.config.porch.kpt.dev   2024-01-10T16:40:26Z
```

Create the Porch namespaces.

```
kubectl apply -f deployments/porch/1-namespace.yaml 
namespace/porch-system created
namespace/porch-fn-system created
```

Edit the `deployments/porch/2-function-runner.yaml` file:
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

Start the Porch function runner deployment. The Porch function runner runs kpt functions for Porch.

```
 kubectl apply -f deployments/porch/2-function-runner.yaml 
serviceaccount/porch-fn-runner created
deployment.apps/function-runner created
service/function-runner created
configmap/pod-cache-config created
```
