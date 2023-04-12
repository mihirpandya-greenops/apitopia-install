## Importing templates

Import the following templates:

Suspend template (wait for approval): https://github.com/GreenOpsInc/templates/blob/main/block/suspend.yaml

Application deployment template: https://github.com/GreenOpsInc/templates/blob/main/block/argocd-step.yaml

Build container template: https://github.com/GreenOpsInc/templates/blob/main/block/docker-image-create-push.yaml

## Example pipelines/setups

### Deploying an application

This pipeline (https://github.com/GreenOpsInc/templates/tree/main/pipelines/deployment-after-approval) waits for an approval from an authorized user, then deploys an application to an environment.

It can easily be structured to deploy across multiple environments either by using the UI or by editing the YAML.

The pipeline uses public demo applications, please create the helm-guestbook application and then run the pipeline using GreenOps.

When creating an application in Argo, use these parameters:
* Git repo: https://github.com/argoproj/argocd-example-apps.git
* Path: helm-guestbook
* Application name: test
* Values file: values.yaml

## Notifications on pods disappearing

When the application gets out of state, a notification will be sent to the slack channel defined in the install script.

## Building images

This pipeline (https://github.com/GreenOpsInc/templates/tree/main/pipelines/build-image) links into an upstream Git repository and builds a Docker image based on the contents of the repo.

To run this workflow, you need a git repository with a Dockerfile (and files that the Dockerfile needs to build an image). A Kubernetes secret with your image repository credentials is also required (so the image can be pushed automatically):

`kubectl create secret docker-registry dockercred --docker-server=<your-registry-server> --docker-username=<your-name> --docker-password=<your-pword> --docker-email=<your-email> -n argo`
