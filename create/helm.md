# Helm Chart Creation and Updates

Used when I manually run helm charts for testing. A version of this is configured through jenkins

## Environment Variables
    see [envVars](./envVars.md)

## Install

On first install, replace the top line of upgrade, with this install line:
```sh

helm install ./helm/ -n helloworld \
```
## Upgrade
```sh
helm install ./release/helm/ -n helloworld \
helm upgrade helloworld ./release/helm/ \
--reuse-values \
--set helloworld.host=$HOST \
--set helloworld.image=${REGISTRY_NAME}demo42/helloworld:aax \
--set imageCredentials.registry=$ACR_NAME.azurecr.io \
--set imageCredentials.username=$(az keyvault secret show \
                                    --vault-name $AKV_NAME \
                                    --name $ACR_NAME-pull-usr \
                                    --query value -o tsv) \
--set imageCredentials.password=$(az keyvault secret show \
                                    --vault-name $AKV_NAME \
                                    --name $ACR_NAME-pull-pwd \
                                    --query value -o tsv)
```
