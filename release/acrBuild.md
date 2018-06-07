## Apline Base Image
```sh
az acr build -t baseimages/node:9-alpine -f ./node-alpine.Dockerfile .
```

## HelloWorld Image
```sh
az acr build -t demo42/helloworld:{{.Build.ID}}  .
```

az acr build-task create \
  -n demo42helloworld \
  --context https://github.com/demo42/helloworld \
  -t demo42/helloworld:{{.Build.ID}} \
  --cpu 2 \
  -f ./Dockerfile \
  --build-arg REGISTRY_NAME=$REGISTRY_NAME \
  --git-access-token $(az keyvault secret show \
                         --vault-name $AKV_NAME \
                         --name $GIT_TOKEN_NAME \
                         --query value -o tsv) \
  --registry $ACR_NAME 
