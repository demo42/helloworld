# Hello world
A single container sample that covers:

- [ACR Tasks](https://aka.ms/acr/tasks) for building & testing container images
- [ACR Helm Chart Repos](https://aka.ms/acr/helm-repos)
- ACR Tasks for deploying Helm Charts to AKS

While the readme may see a bit long, we attempt to follow _best practices_, such as using Azure Key Vault to store secrets.

## Fork the Repo
To complete the sample, git webhook creation on a repo you own will be required.

- Fork the following repositories: 
  - github.com/demo42/helloworld
  - github.com/demo42/helloworld-deploy

## Configure your local environment

- Edit [./env.sh](./env.sh) to represent your environment
- Change directories and apply the environment variables

  ```sh
  cd ./helloworld
  source ./env.sh
  ```

- Login to the az cli

  ```sh
  az login
  ```

- Configure a default registry, to avoid having to specify the registry in each `az acr` command
  ```sh
  az configure --defaults acr=$ACR_NAME
  ```

## Create a GitHub personal access token

To trigger a build on a commit, ACR Tasks needs a personal access token (PAT) to access the git repository.

- Navigate to the PAT creation page on GitHub at https://github.com/settings/tokens/new

- Enter a short **description** for the token, for example, "ACR Build Task Demo"

### Public Repos:
Public repos require the following permissions:

- Under **repo**, enable **repo:status** and **public_repo**

    ![Screenshot of the Public Repo Personal Access Token generation page in GitHub][build-task-new-token-public-repo]

### Private Repos:
- Private repos: add 
  - **repo**, enable **repo:status**, **repo:repo_deployment**, **repo:public_repo**, **repo:invite**
  - **admin:repo_hook**, enable **write:repo_hook**, **read:repo_hook**

    ![Screenshot of the Private Repo Personal Access Token generation page in GitHub][build-task-new-token-private-repo]

### Select the **Generate token** button 

- Copy the generated token and paste into Key Vault

    ![Screenshot of the Personal Access Token][build-task-generated-token]

    ```sh
    az keyvault secret set \
        --vault-name $AKV_NAME \
        --name $GIT_TOKEN_NAME \
        --value 74fef000b0000a00f000000
    ```

## Credentials 
To perform an AKS update using Helm, a service principal is required to pull images from the regsitry and perform run `helm update`. To avoid losing the credentials, while storing them securely, we'll create a service principal, saving the secrets to Azure Key Vault

```sh
# Create a service principal (SP) with:
# - registry pull permissions
# - cluster deploy permissions

# Create a SP with registry pull permissions, saving the created password to a Key Vault secret.
az keyvault secret set \
  --vault-name $AKV_NAME \
  --name $ACR_NAME-deploy-pwd \
  --value $(az ad sp create-for-rbac \
            --name $ACR_NAME-deploy \
            --scopes \
              $(az acr show \
                --name $ACR_NAME \
                --query id \
                --output tsv) \
            --role reader \
            --query password \
            --output tsv)

# Store the service principal ID, (username) in Key Vault
az keyvault secret set \
    --vault-name $AKV_NAME \
    --name $ACR_NAME-deploy-usr \
    --value $(az ad sp show \
              --id http://$ACR_NAME-pull \
              --query appId --output tsv)

# Assign permissions required for Helm Update
az role assignment create \
  --assignee $(az ad sp show \
              --id http://$ACR_NAME-deploy \
              --query appId \
              --output tsv) \
  --role owner \
  --scope $(az aks show \
              --resource-group $AKS_RESOURCE_GROUP \
              --name $AKS_CLUSTER_NAME \
              --query "id" \
              --output tsv)

# Save the tenant for az login --service-principal
az keyvault secret set \
    --vault-name $AKV_NAME \
    --name $ACR_NAME-tenant \
    --value $(az account show \
              --query tenantId \
              -o tsv)
```

## Local (pre-commit) Build
One of the great things about **ACR Tasks** is the ability to run a **quick task** validating the work, before committing to source control.

With configurations complete, create a *quick build** to validate the configurations

- Using [ACR Tasks](https://aka.ms/acr/tasks), execute a **quick build**

  ```sh
  az acr build -t helloworld:{{.Run.ID}} . 
  ```

- List images available, including the newly built image:

  ```sh
  az acr repository show-tags --repository helloworld
  ```

- List tags in lastupdate, descending order. 

  ```sh
  az acr repository show-tags \
    --repository helloworld \
    --orderby time_desc \
    --detail \
    --query "[].{Tag:name,LastUpdate:lastUpdateTime}"
  ```

  > See [Issue: #147]
  (https://github.com/Azure/acr/issues/147) for a change to the default sortorder

## Deploy the Initial Hello World image to AKS
Before we automate helm chart updates, an initial seeding of the app is required as Helm uses separate commands for install and update. 

- Initialize the helm client environment.
  ```sh
  helm init --client-only 
  ```

- Add a helm repo, which refers to the Azure Container Registry, then list the local Helm repos. 

  ```sh
  az acr helm repo add
  helm repo list
  ```
  output:

  ```sh
  NAME    URL
  stable  https://kubernetes-charts.storage.googleapis.com
  local   http://127.0.0.1:8879/charts
  demo42  https://demo42.azurecr.io/helm/v1/repo

  > **Note**: By setting `az configure --defaults acr=demo42`, `az acr helm repo add --name demo42` isn't required

- Package the helm chart from helloworld-deploy [helloworld-deploy](https://github.com/demo42/helloworld-deploy), which should be cloned alongside the helloworld folder

  ```sh
  helm package \
    --version 1.0.0 \
    ../helloworld-deploy/helm/helloworld
  ```

- Push the packaged helm chart to the registry

  ```sh
  az acr helm push ./helloworld-1.0.0.tgz

  ```
- Refresh the local Helm index

  ```sh
  az acr helm repo add
  ```
  
- Fetch the Helm Chart

    ```sh
    helm fetch --untar $ACR_NAME/helloworld --untardir ./charts
    ```

- Set the tag, based on the most recent run-id, excluding latest

  ```sh
  az acr repository show-tags \
      --repository helloworld \
      --orderby time_desc \
      --detail \
      --query "[].{Tag:name,LastUpdate:lastUpdateTime}"
  ```

- Install the initial deployment

  ```sh
  helm install ./charts/helloworld -n helloworld \
  --set helloworld.host=$HOST \
  --set helloworld.image=$ACR_NAME.azurecr.io/helloworld:$TAG \
  --set imageCredentials.registry=$ACR_NAME.azurecr.io \
  --set imageCredentials.username=$(az keyvault secret show \
                                         --vault-name $AKV_NAME \
                                         --name $ACR_NAME-pull-usr \
                                         --query value -o tsv) \
  --set imageCredentials.password=$(az keyvault secret show \
                                         --vault-name $AKV_NAME \
                                         --name $ACR_NAME-pull-pwd \
                                         --query value -o tsv)
  ```
- Verifying the registry credentials are being retrieved
  ```sh
  echo imageCredentials.username=$(az keyvault secret show \
                                          --vault-name $AKV_NAME \
                                          --name $ACR_NAME-pull-usr \
                                          --query value -o tsv) \
    '\n' \
    imageCredentials.password=$(az keyvault secret show \
                                          --vault-name $AKV_NAME \
                                          --name $ACR_NAME-pull-pwd \
                                          --query value -o tsv)
  ```
- Resetting the registry credentials (secret)
  ```sh
  helm upgrade $APP_NAME ./charts/helloworld \
    --reuse-values \
    --wait \
    --set helloworld.image=$ACR_NAME.azurecr.io/helloworld:$TAG \
    --set imageCredentials.registry=$ACR_NAME.azurecr.io \
    --set imageCredentials.username=$(az keyvault secret show \
                                          --vault-name $AKV_NAME \
                                          --name $ACR_NAME-pull-usr \
                                          --query value -o tsv) \
    --set imageCredentials.password=$(az keyvault secret show \
                                          --vault-name $AKV_NAME \
                                          --name $ACR_NAME-pull-pwd \
                                          --query value -o tsv)
  ```  
- Resetting the registry credentials, with the `kubectl` cli

  ```sh
  kubectl create secret \
    docker-registry acrdemossecret \
    --docker-server=acrdemos.azurecr.io \
    --docker-username=$(az keyvault secret show \
                          --vault-name $AKV_NAME \
                          --name $ACR_NAME-pull-usr \
                          --query value -o tsv) \
   --docker-password=$(az keyvault secret show \
                          --vault-name $AKV_NAME \
                          --name $ACR_NAME-pull-pwd \
                          --query value -o tsv) \
   --docker-email=dont@bother.me
  ```

- Verifying the registry crednetials work
  ```sh
  docker login $ACR_NAME.azurecr.io \
    -u $(az keyvault secret show \
          --vault-name $AKV_NAME \
          --name $ACR_NAME-pull-usr \
          --query value -o tsv) \
    -p $(az keyvault secret show \
          --vault-name $AKV_NAME \
          --name $ACR_NAME-pull-pwd \
          --query value -o tsv)
  
  docker pull $ACR_NAME.azurecr.io/helloworld:$TAG
  ```

- Query for an EXTERNAL_IP address to be provisioned.

  ```sh
  kubectl get svc
  ```

- Repeat until `helloworld-nginx-ingress-controller` returns a valid IP under **EXTERNAL-IP**

  ```sh
  NAME                                       TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)                      AGE
  helloworld-nginx-ingress-controller        LoadBalancer   10.0.235.75    40.117.59.143   80:30120/TCP,443:30141/TCP   21m
  helloworld-nginx-ingress-default-backend   ClusterIP      10.0.51.179    <none>          80/TCP                       21m
  helloworld-svc                             ClusterIP      10.0.62.141    <none>          80/TCP                       21m
  ```

## Assign the static IP a dns name

- Navigate to https://portal.azure.com/
- Navigate to resource groups
- Filter resources groups to those starting with MC_

    ![Screenshot of Hidden AKS Resource Group][aks-hidden-resource-group]

- Click into the resource group
- Click into the public ips, finding the one that has the same IP address as identified above

    ![Screenshot of Hidden AKS Resource Group][aks-public-ips]
    ![Screenshot of Specific Public IP Configuration][aks-specific-ip]

- Configure (1) the **Public IP**, assigning a notable dns name (2)

    ![Screenshot of DNS Configuration][aks-configure-dns]

- Browse the site, using the DNS name

    ![Screenshot of Hello World Deployed to AKS][browse-helloworld]

At this point, you should have a fully deployed HelloWorld app that looks similar to the above.
Proceed to the next step to automate container builds

## Automate Build and Deploy
With a basic/manual build and helm install complete, we'll transition to building & deploying an image to an AKS cluster.

ACR Tasks support multi-step operations, including the execution of a graph of containers. 

The [./acr-task.yaml](./acr-task.yaml) file represents the graph of steps executed:

- build the helloworld image, with two tags
- run the newly built image, in the task environment, detaching so a quick test can be performed
- run a quick functional test, using a [curl image](), passing it the url of the helloworld image. The url is based on the `id:` of the task. 
- push the validated image to the registry
- run the [helm image](https://github.com/AzureCR/cmd/blob/master/helm/Dockerfile), used for helm deployments. 

### Configuring AKS Permissions

To achieve a Helm Chart deployment, permissions to the AKS cluster are required. Since this is a headless service, the previously configured service principal is used. 


- Run a quick-task over the local source, validating the build and helm deploy. 

  ```sh
  az acr run \
    -f acr-task.yaml \
    . \
    --set CLUSTER_NAME=$AKS_CLUSTER_NAME \
    --set CLUSTER_RESOURCE_GROUP=$AKS_RESOURCE_GROUP \
    --set TENANT=$(az keyvault secret show \
              --vault-name ${AKV_NAME} \
              --name $ACR_NAME-tenant \
              --query value -o tsv) \
    --set SP=$(az keyvault secret show \
              --vault-name ${AKV_NAME} \
              --name $ACR_NAME-serviceaccount-user \
              --query value -o tsv) \
    --set PASSWORD=$(az keyvault secret show \
              --vault-name ${AKV_NAME} \
              --name $ACR_NAME-serviceaccount-pwd \
              --query value -o tsv) \
    --registry $ACR_NAME 
  ```

## Automatically build helloworld
With a quick build complete, configure an automated build that triggers on **git commits** and **base image updates**. 

- Create an ACR Task with a set of variables used within the task, such as the AKS name and a service principal used for accessing AKS. 
  ```sh
  az acr task create \
    -n helloworld-multistep \
    -f acr-task.yaml \
    --context $GIT_REPO \
    --git-access-token $(az keyvault secret show \
                  --vault-name $AKV_NAME \
                  --name $GIT_TOKEN_NAME \
                  --query value -o tsv) \
    --set CLUSTER_NAME=$AKS_CLUSTER_NAME \
    --set CLUSTER_RESOURCE_GROUP=$AKS_RESOURCE_GROUP \
    --set-secret TENANT=$(az keyvault secret show \
              --vault-name ${AKV_NAME} \
              --name $ACR_NAME-serviceaccount-tenant \
              --query value -o tsv) \
    --set-secret SP=$(az keyvault secret show \
              --vault-name ${AKV_NAME} \
              --name demo42-serviceaccount-user \
              --query value -o tsv) \
    --set-secret PASSWORD=$(az keyvault secret show \
              --vault-name ${AKV_NAME} \
              --name demo42-serviceaccount-pwd \
              --query value -o tsv) \
    --registry $ACR_NAME 
  ```
  > With future Task enhancements, a [Microsoft Identity (MSI)](https://docs.microsoft.com/azure/active-directory/managed-identities-azure-resources/overview ) can be associated with a Task, avoiding the need configure service principal details above.

### Commit a code change
  
- Monitor the current builds using a bash environment, including [Azure cloud shell](https://shell.azure.com)
  ```sh
  watch -n1 az acr build-task list-builds 
  ```

- View the current executing task, without having to specify the `--run-id`

  ```sh
  az acr build-task logs
  ```

- View a specific task by the `--run-id`

  ```sh
  az acr build-task logs --run-id aabh
  ```

- View the update in the AKS Cluster

  > **TODO**: navigate to the helloworld image, describing how to get the url


## Base Image Updates

- Update the base image

  ```sh
  docker build -t baseimages/node:9 \
    -f node-jessie.Dockerfile \
    .
  ```
- Switch the dockerfile to -alpine

  Update the base image for Apline
  ```sh
  docker build -t jengademos.azurecr.io/baseimages/node:9-alpine -f node-alpine.Dockerfile .
  docker push jengademos.azurecr.io/baseimages/node:9-alpine
  ```

## Update Demo42 Backcolor
  ```sh
  docker tag jengademos.azurecr.io/baseimages/microsoft/aspnetcore-runtime:linux-2.1-azure \
    jengademos.azurecr.io/baseimages/microsoft/aspnetcore-runtime:linux-2.1
  docker push \
    jengademos.azurecr.io/baseimages/microsoft/aspnetcore-runtime:linux-2.1
  ```
## Deploy to AKS

- Get the cluster you're working with
  ```sh
  az aks list
  ```

- get credentials for the cluster

  ```sh
  az aks get-credentials -n [name] -g [group]
  ```
- Set variables

  ```sh
  export HOST=http://demo42-helloworld.eastus.cloudapp.azure.com/
  export ACR_NAME=jengademos
  export TAG=aa42
  export AKV_NAME=jengademoskv
  ```

- Deploy with Helm

  Set the 
  ```sh
  helm install ./release/helm/ -n helloworld \
  --set helloworld.host=$HOST \
  --set helloworld.image=jengademos.azurecr.io/demo42/helloworld:$TAG \
  --set imageCredentials.registry=$ACR_NAME.azurecr.io \
  --set imageCredentials.username=$(az keyvault secret show \
                                         --vault-name $AKV_NAME \
                                         --name $ACR_NAME-pull-usr \
                                         --query value -o tsv) \
  --set imageCredentials.password=$(az keyvault secret show \
                                         --vault-name $AKV_NAME \
                                         --name $ACR_NAME-pull-pwd \
                                         --query value -o tsv)
```
## Helm Package, push
helm package \
    --version 1.0.1 \
    ./helm/helloworld

az acr helm push \
    ./helloworld-1.0.1.tgz \
    --force -o table

## Update the local cache
az acr helm repo add

helm fetch demo42/helloworld

helm repo list

## Upgrade
```sh
helm upgrade helloworld ./helm/helloworld/ \
  --reuse-values \
  --set helloworld.image=demo42.azurecr.io/helloworld:$TAG
```
## Create the webhook header
  Create a value in Key Vault to save for future reference
  ```sh
  az keyvault secret set \
    --vault-name $AKV_NAME \
    --name demo42-helloworld-webhook-auth-header \
    --value "Authorization: Bearer "[value]
  ```

## Create ACR Webhook for deployments
  ```sh
  az acr webhook create \
    -r $ACR_NAME \
    --scope demo42/helloworld:* \
    --actions push \
    --name demo42HelloworldEastus \
    --headers Authorization=$(az keyvault secret show \
                              --vault-name $AKV_NAME \
                              --name demo42-helloworld-webhook-auth-header \
                              --query value -o tsv) \
    --uri http://jengajenkins.eastus.cloudapp.azure.com/jenkins/generic-webhook-trigger/invoke
  ```
[build-task-new-token-public-repo]: ./docs/build-task-new-token-public-repo.png
[build-task-new-token-private-repo]: ./docs/build-task-new-token-private-repo.png

[build-task-generated-token]: ./docs/build-task-generated-token.png
[aks-hidden-resource-group]: ./docs/aks-hidden-resource-group.png
[aks-public-ips]: ./docs/aks-public-ips.png
[aks-specific-ip]: ./docs/aks-specific-ip.png
[aks-configure-dns]: ./docs/aks-configure-dns.png
[browse-helloworld]: ./docs/browse-helloworld.png

