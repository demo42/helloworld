# Iterate quickly, pre-commit/post commit to App Service Containers


## Fork, Then Clone this Repo

Fork https://github.com/demo42/helloworld to your own registry
```sh
export HELLOWORLD_REPO=https://github.com/[YOUR-REPO]/helloworld
```

## Preset

A few presets before doing the demo

### Base Image

Have a base image for node in the current registry. This will be used later in the demo, but it helps to have it setup now

- See the [base-image-node Readme](https://github.com/demo42/baseimage-node/blob/master/README.md) for more info

### Common Environment Variables

- Using a bash environment, or [Cloud Shell](https://shell.azure.com), paste the [Env Vars](./envVars.md)


# Start the Demo

## Local Build
- Review server.js and Dockerfile in VS Code
- Show `docker build -t helloworld:someunique_id .` 
- CTRL+C to keep the line, but don't execute the docker build command

## AC Cloud Build

- Show az acr build, with the same syntax

  ```sh
  az acr build -t "helloworld:{{.Build.ID}}" .
  ```

- Add a second tag

  App Service doesn't yet know how to dynamically update a deployment, by reading the webhook payload, but that's coming. So, we'll just use two tags

  ```sh
  az acr build -t "helloworld:{{.Build.ID}}" -t helloworld:release .
  ```

## List Images

- We can see the images in ACR
  ```sh
  az acr repository show-tags --repository helloworld
  ```

- Show with the VS Code ACR enhanced Docker Extension


## Deploy to App Service

- From the portal, select the image in the registry
- Select deploy to Web App
- Walk through the configurations

## Deploy an update to App Service

- Make a change to server.js
- Push the change, with the same command we used prior

  ```sh
  az acr build -t "helloworld:{{.Build.ID}}" -t helloworld:release .
  ```

- View the change in the deployed App Service
## Create a Task, triggered by Git Commits

- Switch to (Cloud Shell)[shell.azure.com]
- Create the build task
  ```sh
  az acr build-task create \
    -t helloworld:{{.Build.ID}} \
    -t helloworld:release \
    -n demo42helloworld \
    --context https://github.com/demo42/helloworld \
    --git-access-token $(az keyvault secret show \
                        --vault-name $AKV_NAME \
                        --name $GIT_TOKEN_NAME \
                        --query value -o tsv)
  ```

- Commit a code change
  
  Monitor the current builds
  ```sh
  watch -n1 az acr build-task list-builds 
  ```

- View the current executing builds

  ```sh
  az acr build-task logs
  ```

## Base Image Updates

- Update the background color
- Open baseimage-node\Dockerfile
- Change the BACKGROUND_COLOR to green, yellow or orange
- Commit the change 
-  Monitor the current builds
  ```sh
  watch -n1 az acr build-task list-builds 
  ```
