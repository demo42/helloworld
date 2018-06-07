
# Parameters used for az cli commands
Used for most of the scripts here

```sh
export DEMO_NAME=demo42

export LOCATION_TLA=eus
export LOCATION=eastus
export ENV_NAME=staging
export RESOURCE_GROUP=$DEMO_NAME-$ENV_NAME-${LOCATION_TLA}
export RESOURCE_GROUP_REGION=$DEMO_NAME-${LOCATION_TLA}

export AKV_NAME=$DEMO_NAME

export ACR_NAME=$DEMO_NAME
# fully qualified url of the registry. 
export REGISTRY_NAME=${ACR_NAME}.azurecr.io/ 

export GIT_TOKEN_NAME=stevelasker-git-access-token # keyvault secret name
export PAT=#[git token]


export HOST=helloworld.${LOCATION}.cloudapp.azure.com
```