#!/bin/sh
kubectl config get-contexts
echo "\nEnter the desired Kubernetes cluster: "
read desired_cluster
kubectl config use-context $desired_cluster

kubectl create ns argocd
kubectl create ns argo
kubectl create ns greenops


echo "\nEnter the name of the cluster registed in GreenOps: "
read cluster_name

echo "\nEnter the cluster's token generated from GreenOps: "
read cluster_token

echo "\nEnter the Postgres token provided: "
read postgres_token

echo "\nEnter the S3 token provided: "
read s3_token
kubectl create secret generic greenops-apikey-secret --from-literal=apikey=$cluster_token -n greenops
kubectl create secret generic greenops-postgres --from-literal=username=postgres --from-literal=password=$postgres_token -n argo
kubectl create secret generic greenops-s3 --from-literal=accesskey=AKIAWBLFWVNFWQ7F4WLG --from-literal=secretkey=$s3_token -n argo

helm repo add argo https://argoproj.github.io/argo-helm
helm repo update argo

echo "\nWhat URL should Argo CD have?: "
read argocd_url

echo "\nEnter your Slack token to set up notifications: "
read slack_token
kubectl create secret generic argocd-notifications-secret --from-literal=slack-token=$slack_token -n argocd

echo "\nWhat channel should messages be sent to?: "
read slack_channel

sed -e 's/GREENOPS_ARGOCD_URL/'$argocd_url'/g' -e 's/SUPPORT_CHANNEL_NAME/'$slack_channel'/g' argocd-values.yaml  > argocd-values-temporary.yaml
helm install greenops-cd argo/argo-cd --namespace argocd --version 5.24.1 -f argocd-values-temporary.yaml
rm argocd-values-temporary.yaml

echo "\nWhat URL should Argo Workflows have?: "
read argowf_url

echo "\nEnter the GreenOps URL: "
read greenops_url

kubectl apply -f argowf-role.yaml
sed -e 's/GREENOPS_URL/'$greenops_url'/g' -e 's/GREENOPS_CLUSTER_NAME/'$cluster_name'/g' argowf-values.yaml  > argowf-values-temporary.yaml
helm install greenops-wf argo/argo-workflows --namespace argo --version 0.23.1 -f argowf-values-temporary.yaml
rm argowf-values-temporary.yaml

kubectl wait --for=condition=ready pod --all -n argocd
helm repo add greenops https://greenopsinc.github.io/charts
helm repo update greenops
helm install greenops-daemon greenops/greenops-daemon --version 1.0.1 --set 'common.imageCredentials.enabled=false' --set 'common.clusterName='$cluster_name'' --set 'common.argo.cd.internalUrl=greenops-cd-argocd-server.argocd.svc.cluster.local' --set 'common.argo.workflows.internalUrl=greenops-wf-argo-workflows-server.argo.svc.cluster.local' --set 'common.argo.workflows.url='$argowf_url'' --set 'common.greenopsServer.url='$greenops_url'' --set 'common.commandDelegator.url='$greenops_url''
argocd_secret=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
kubectl create secret generic argocd-user --from-literal=username=admin --from-literal=password=$argocd_secret -n argo
