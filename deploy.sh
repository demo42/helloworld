#!/bin/sh

set -e
# SP, PASSWORD , CLUSTER_NAME, CLUSTER_RESOURCE_GROUP
az configure --defaults acr=$ACR_NAME
mkdir /tmp

az login \
    --service-principal \
    --username $SP \
    --password $PASSWORD \
    --tenant $TENANT  > /dev/null

az aks get-credentials \
    -g $CLUSTER_RESOURCE_GROUP \
    -n $CLUSTER_NAME 

echo -- helm init --client-only --
helm init --client-only # > /dev/null

echo -- az acr helm repo add --
az acr helm repo add 

echo -- helm fetch --untar $ACR_NAME/$APP_NAME --
helm fetch --untar $ACR_NAME/$APP_NAME

echo -- helm upgrade $ACR_NAME ./$APP_NAME --
helm upgrade $ACR_NAME ./$APP_NAME/ \
    --reuse-values \
    --set web.image=$RUN_REGISTRY/$APP_NAME:$RUN_ID
