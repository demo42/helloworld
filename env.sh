#!/bin/sh

# Replace these values for your configuration
# I've left our values in, as we use this for our demos, providing some examples
export ACR_NAME=demo42t
export RESOURCE_GROUP=$ACR_NAME
export RESOURCE_GROUP_LOCATION=southcentralus
export REGISTRY_NAME=${ACR_NAME}.azurecr.io/ 

export AKS_NAME=demo42-dev
export AKS_RG_NAME=demo42-dev-scus

# App service Configuration
export APP_SERVICE_URL=https://demo42-scus.azurewebsites.net

# Cloned Github Repo
export GIT_REPO=https://github.com/demo42/helloworld.git
export GIT_NODE_UPSTREAM=https://github.com/demo42/upstream-node.git
export GIT_NODE_IMPORT=https://github.com/demo42/staging-node.git

# Azure Keyvault Name
export AKV_NAME=demo42
# Token Name within Keyvault
export GIT_TOKEN_NAME=demo42-git-token 

