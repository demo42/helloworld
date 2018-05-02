# node-helloworld
Sample app for demos

## Setup a default registry

```sh
export ACR_NAME=jengademos
az configure --defaults acr=$ACR_NAME
```
## Clone the repo
```sh
git clone github.com/
```

## Local Build
```sh
# Build
az acr build -t helloworld:{{.Build.ID}} . 
#List Images
az acr repository show-tags --repository helloworld
```
 Common Environment Variables
```sh
# Replace these values for your configuration
# I've left our values in, as we use this for our demos, providing some examples
export ACR_NAME=jengademos
export RESOURCE_GROUP=$ACR_NAME
# fully qualified url of the registry. 
# This is where your registry would be
# Accounts for registries in dogfood or other clouds like .gov, Germany and China
export REGISTRY_NAME=${ACR_NAME}.azurecr.io/ 
export AKV_NAME=$ACR_NAME-vault # name of the keyvault
export GIT_TOKEN_NAME=stevelasker-git-access-token # keyvault secret name
```

## Create a build task
- Populate your GIT Personal Access Token
  ```sh
  export PAT=$(az keyvault secret show \
                --vault-name $AKV_NAME \
                --name $GIT_TOKEN_NAME \
                --query value -o tsv)
  ```
```sh
az acr build-task create \
  -n helloworld \
  -c https://github.com/demo42/helloworld \
  -t helloworld:{{.Build.ID}} \
  --cpu 2 \
  --git-access-token=$PAT
```
