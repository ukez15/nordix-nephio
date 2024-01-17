# Deploying custom porch images

This section covers the process to build and deploy the porch images to a given kind cluster.

# Table of Contents
1. [Prerequisites](#Prerequisites)
2. [Clone Porch and deploy with custom images](#Clone-Porch-and-deploy-with-custom-images)
3. [Connect the Gitea repositories to Porch](#Connect-the-Gitea-repositories-to-Porch)
4. [Teardown the custom porch deployment](#Teardown-the-custom-porch-deployment)

## Prerequisites
This guide assumes that **steps 1 to 6** of the [Starting with Porch](#../starting-with-porch/README.md) tutorial have been executed.

## Clone Porch and deploy with custom images
Clone the [porch project](https://github.com/nephio-project/porch.git)  from Github onto your environment using whatever cloning process for development your organization recommends. 
Here, we assume Porch is cloned into a directory called `porch`.

To allow the custom image for the porch-controllers be pulled from the kind docker ctr, we need to patch the ImagePullPolicy of the porch-controllers deployment.
Check that porch is up and running:
```
kubectl get po -n porch-system
```
Patch the porch-controllers deployment
```
kubectl patch deployment -n porch-system porch-controllers -p '{"spec": {"template": {"spec":{"containers":[{"name": "porch-controllers", "imagePullPolicy":"IfNotPresent"}]}}}}'
```

We will now use the make target `run-in-kind` to build the images and re deploy the porch deployments to use them.

Here, we pass the following vars to the make target:

| VAR  | DEFAULT  | EG  |
|---|---|---|
|  IMAGE_TAG | $(git_tag)-dirty  | test  |
|  KUBECONFIG | $(CURDIR)/deployments/local/kubeconfig  | ~/.kube/kind-management-config  |
|  KIND_CONTEXT_NAME | kind  | management  |
 
```
cd porch

make run-in-kind IMAGE_TAG='test' KUBECONFIG='~/.kube/kind-management-config' KIND_CONTEXT_NAME='management'
```
This will build the porch images with the given tag, load them to the kind docker ctr and rollout those images to the porch deployments.

> **_NOTE:_** The docker build can take some time to complete on first run. Future refinements to the make targets will reduce build and or deploy times.

Check that the new images have been deployed:

```
kubectl get deployments -n porch-system -o wide
```
Sample output:
```
NAME                READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS          IMAGES                                   SELECTOR
function-runner     2/2     2            2           81m   function-runner     porch-kind/porch-function-runner:test3   app=function-runner
porch-controllers   1/1     1            1           81m   porch-controllers   porch-kind/porch-controllers:test3       k8s-app=porch-controllers
porch-server        1/1     1            1           81m   porch-server        porch-kind/porch-server:test3            app=porch-server
```

## Connect the Gitea repositories to Porch

If necessary, (re)create the porch Repository Custom Resources.

Create a demo namespace:

```
kubectl create namespace porch-demo
```

Create a secret for the Gitea credentials in the porch-demo namespace:

```
kubectl create secret generic gitea \
    --namespace=porch-demo \
    --type=kubernetes.io/basic-auth \
    --from-literal=username=nephio \
    --from-literal=password=secret
```

Now, define the Gitea repositories in Porch:
```
kubectl apply -f ~/nordix-nephio/tutorials/starting-with-porch/porch-repositories.yaml
```

Check that the repositories have been correctly created:
```
kubectl get repositories -n porch-demo
NAME                  TYPE   CONTENT   DEPLOYMENT   READY   ADDRESS
edge1                 git    Package   true         True    http://172.18.255.200:3000/nephio/edge1.git
external-blueprints   git    Package   false        True    https://github.com/nephio-project/free5gc-packages.git
management            git    Package   false        True    http://172.18.255.200:3000/nephio/management.git
```

## Teardown the custom porch deployment

Delete the porch resources:

```
cd ~/porch

kubectl delete --wait --recursive --filename ./.build/deploy --kubeconfig ~/.kube/kind-management-config
```

The following CRD needs it's `finalizer` to be patched to allow it to be removed.
In another terminal, execute the following to patch the CRD. This will allow the previous cmd to complete:

```
kubectl patch crd/packagerevs.config.porch.kpt.dev -p '{"metadata":{"finalizers":[]}}' --type=merge
```

Check that all porch resources have been deleted:
```
kubectl get all -n porch-system

kubectl api-resources | grep porch
```

