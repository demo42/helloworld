# Hello world

A single container sample that covers:

> While the readme may see a bit long, we attempt to follow _best practices_, such as using Azure Key Vault to store secrets.

## Assumptions

- A current version of the [az cli](https://docs.microsoft.com/cli/azure/install-azure-cli?view=azure-cli-latest)
- An instance App Service Containers

## Configure your local environment

- Edit [./env.sh](./env.sh) to represent your specific environment and resource names
- CD into helloworld and apply the environment variables with [source](https://bash.cyberciti.biz/guide/Source_command)

  ```sh
  cd ./helloworld
  source ./env.sh
  ```

- Login to the az cli

  ```sh
  az login
  ```

- Configure a default registry, to avoid having to specify the registry in each `az acr` command. This uses the [env.sh](./env.sh) values set above.

  ```sh
  az configure --defaults acr=$ACR_NAME
  ```

## Create a GitHub personal access token

To trigger a build on a commit, [ACR Tasks](https://aka.ms/acr/tasks) needs a personal access token (PAT) to access the git repository.

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

## Automate Build and Deploy

With a basic/manual build and deploy complete, we'll transition to building & deploying based on a git commit, with base image updates.

ACR Tasks support multi-step operations, including the execution of a graph of containers.

The [./acr-task.yaml](./acr-task.yaml) file represents the graph of steps executed:

- build the helloworld image, with two tags
- run the newly built image, in the task environment, detaching so a quick test can be performed
- run a quick functional test, using a [curl image](), passing it the url of the helloworld image. The url is based on the `id:` of the task.

> Note: the curl doesn't actually validate the results, yet. This is a good TODO:

- push the validated image to the registry

## Automatically build helloworld

With a quick build complete, configure an automated build that triggers on **git commits** and **base image updates**.

- Create an ACR Task with a set of variables used within the task, such as the AKS name and a service principal used for accessing AKS.

  ```sh
  az acr task create \
    --registry $ACR_NAME \
    -n helloworld-app-service \
    -f acr-task-app-service.yaml \
    --context $GIT_HELLOWORLD \
    --git-access-token $(az keyvault secret show \
                  --vault-name $AKV_NAME \
                  --name $GIT_TOKEN_NAME \
                  --query value -o tsv)
  ```

- Manually run the task

    ```sh
    az acr task run -n helloworld-app-service
    ```
