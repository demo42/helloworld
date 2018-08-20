
# Parameters used for az cli commands
Used for most of the scripts here

```sh
export DEMO_NAME=demo42

export LOCATION=eastus
export RESOURCE_GROUP=$DEMO_NAME-${LOCATION}

export AKV_NAME=$DEMO_NAME

export ACR_NAME=$DEMO_NAME
# fully qualified url of the registry. 
export REGISTRY_NAME=${ACR_NAME}.azurecr.io/ 

export GIT_TOKEN_NAME=demo42-git-access-token # keyvault secret name
```
