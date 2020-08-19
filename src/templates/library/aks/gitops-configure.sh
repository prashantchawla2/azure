#!/bin/bash

function join_by { local d=$1; shift; echo -n "$1"; shift; printf "%s" "${@/#/$d}"; }

CLUSTER_RG=$1
CLUSTER=$2
GIT_URL=$3
GIT_BRANCH=$4
KEY_VAULT=$5
GIT_PATH=$(join_by \\\, ${@:6:$#})

################# Installing Prerequisites #################

# Install kubctl
curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.18.0/bin/linux/amd64/kubectl
chmod +x ./kubectl
mv ./kubectl /usr/local/bin/kubectl

# Install helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

# Install fluxctl
wget https://github.com/fluxcd/flux/releases/download/1.19.0/fluxctl_linux_amd64
chmod +x fluxctl_linux_amd64

################# Connect to Cluster #################

# Get the cluster credentials
az aks get-credentials -g $CLUSTER_RG -n $CLUSTER

################# Configure Istio #################

./istio-configure.sh

################# Configure GitOps #################

# Installing flux and helm operator to cluster
helm repo add fluxcd https://charts.fluxcd.io
kubectl apply -f https://raw.githubusercontent.com/fluxcd/helm-operator/master/deploy/crds.yaml

FLUX_NAMESPACE=$(kubectl get namespace fluxx --ignore-not-found)
if test -z "$FLUX_NAMESPACE" 
then
  kubectl create namespace flux
else
  echo "Flux Namespace already created. Skipping creation..."
fi

mkdir -p ~/.ssh && chmod 700 ~/.ssh
ssh-keyscan innovamps.visualstudio.com >> ~/.ssh/known_hosts && chmod 644 ~/.ssh/known_hosts
eval $(ssh-agent -s)
KNOWN_HOSTS=$(ssh-keyscan innovamps.visualstudio.com)

helm upgrade -i flux fluxcd/flux --set git.url=$GIT_URL --set rbac.create=true --set git.branch=$GIT_BRANCH --set git.path=$GIT_PATH --set-string ssh.known_hosts="${KNOWN_HOSTS}" --namespace flux --wait

helm upgrade -i helm-operator fluxcd/helm-operator --set git.ssh.secretName=flux-git-deploy --namespace flux --set helm.versions=v3 --wait

# Configure flux to have write access to git repostiory to update kubernetes configs.
DEPLOY_KEY=$(./fluxctl_linux_amd64 identity --k8s-fwd-ns flux)

################# Registering Deploy Key to Key Vault #################
az keyvault secret set --vault-name $KEY_VAULT --name "gitops-deploy-key" --value "$DEPLOY_KEY"

################# Configure Kubernetes Dashboard #################

# Give the dashboard service in kubernetes cluster admin rights such that it is authorized access to the cluster data.
DASHBOARD_ROLE_BINDING=$(kubectl get clusterrolebinding kubernetes-dashboard --ignore-not-found)
if test -z "$DASHBOARD_ROLE_BINDING" 
then
  kubectl create clusterrolebinding kubernetes-dashboard -n kube-system --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard
else
  echo "kubernetes-dashboard cluster role binding already created. Skipping creation..."
fi
