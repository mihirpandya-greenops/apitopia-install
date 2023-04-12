#!/bin/sh
kubectl config get-contexts
echo "Enter the desired Kubernetes cluster: "
read desired_cluster
kubectl config use-context $desired_cluster

helm repo add argo https://argoproj.github.io/argo-helm
helm repo update argo
helm uninstall greenops-cd --namespace argocd
helm uninstall greenops-wf --namespace argo
kubectl delete -f argowf-role.yaml
helm uninstall greenops-daemon

kubectl delete ns argocd
kubectl delete ns argo
kubectl delete ns greenops
