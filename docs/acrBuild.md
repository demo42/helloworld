## Apline Base Image
```sh
az acr build -t baseimages/node:9-alpine -f ./node-alpine.Dockerfile .
```
## Default Registry
```sh
az configure --defaults acr=demo42
```

## HelloWorld Build-Task - demo-clean
```sh

az acr build-task create \
  -t demo42/helloworld:{{.Build.ID}} \
  -t demo42/helloworld:release \
  -n demo42helloworld \
  -f helmTask.yaml \
  --context https://github.com/demo42/helloworld \
  --git-access-token $(az keyvault secret show \
                         --vault-name demo42 \
                         --name demo42-git-token \
                         --query value -o tsv)
```
## Helloworld Build Task for Kubernetes w/Helm
```sh
az acr build-task create \
  -t demo42/helloworld:{{.Build.ID}} \
  -n demo42helloworldk8 \
  -f helmTask.yaml \
  --context https://github.com/demo42/helloworld \
  --git-access-token $(az keyvault secret show \
                         --vault-name demo42 \
                         --name demo42-git-token \
                         --query value -o tsv)
```

## HelloWorld Image Parameterized
```sh
az acr build -t demo42/helloworld:{{.Build.ID}}  .
```
```sh
az acr build-task create \
  -t demo42/helloworld:{{.Build.ID}} \
  -t demo42/helloworld:release \
  -n demo42helloworld \
  --context https://github.com/demo42/helloworld \
  --build-arg REGISTRY_NAME=$REGISTRY_NAME \
  --git-access-token $(az keyvault secret show \
                         --vault-name $AKV_NAME \
                         --name $GIT_TOKEN_NAME \
                         --query value -o tsv) \
  --registry $ACR_NAME 
```
