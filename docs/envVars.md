# Replace these values for your configuration
# I've left our values in, as we use this for our demos, providing some examples
```sh
export DEMO_NAME=demo42
export ACR_NAME=$DEMO_NAME
export AKV_NAME=$DEMO_NAME # name of the keyvault
export LOCATION=eastus
export RESOURCE_GROUP=$DEMO_NAME
export BASE_IMAGE_REPO=https://github.com/demo42/baseimage-node
export GIT_TOKEN_NAME=${DEMO_NAME}-git-token # keyvault secret name

# fully qualified url of the registry. 
# This is where your registry would be
# Accounts for registries in dogfood or other clouds like .gov, Germany and China
export REGISTRY_NAME=${ACR_NAME}.azurecr.io/ 

az configure --defaults acr=$ACR_NAME
```

