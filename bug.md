**BUG REPORT**:

**What happened?**:

`helm repo update` doesn't accurately reflect the updated index in the registry
had to issue `az acr helm repo add` which:
- appears overkill, as I already have the repo added
- isn't consistent with the helm ci

**What did you expect to happen?**:

`helm repo update` should sync the client repo info with the registry repo status


**How do you reproduce it (as minimally and precisely as possible)?**:

```sh
az group create -n deleteme -l eastus
az acr create -n demo44 -g deleteme --sku standard
helm init --client-only
helm fetch \
    stable/wordpress \
    --untar \
    --untardir ./charts/stable

az acr helm repo add -n demo44

helm package \
    --version 1.0.0 \
    ./charts/stable/wordpress

az acr helm push \
    ./wordpress-1.0.0.tgz \
    -n demo44 \
    -o table

helm fetch \
    demo44/wordpress \
    --untar \
    --untardir ./charts/demo44
```
Receive the error:

`Error: chart "wordpress" matching  not found in demo44 index. (try 'helm repo update'). no chart name found`

```sh
helm repo update
helm fetch \
    demo44/wordpress \
    --untar \
    --untardir ./charts/demo44
```
## We now have a good base to reference

Create a 1.0.1 version
```sh
helm package \
    --version 1.0.1 \
    ./charts/stable/wordpress

az acr helm push \
    ./wordpress-1.0.1.tgz \
    -n demo44 \
    -o table

helm repo update

helm fetch \
    demo44/wordpress \
    --untar \
    --untardir ./charts/demo44
```
At this point, it appears as if we would have version 1.0.1, however it's still version 1
```sh
helm fetch \
    demo44/wordpress \
    --untar \
    --untardir ./charts/demo44 \
    --version 1.0.1
```
However, we get an error, that says (try 'helm repo update'):

`Error: chart "wordpress" matching 1.0.1 not found in demo44 index. (try 'helm repo update'). No chart version found for wordpress-1.0.1`

Reference the local cache:
```sh
helm search demo44/
NAME                    CHART VERSION   APP VERSION     DESCRIPTION
demo44/wordpress        1.0.0           4.9.8           Web publishing platform for building blogs and websites.
```
Use the `az acr helm repo add` command to update the client
```sh
az acr helm repo add
helm search demo44/
```
produces:
```sh
NAME                    CHART VERSION   APP VERSION     DESCRIPTION
demo44/wordpress        1.0.1           4.9.8           Web publishing platform for building blogs and websites.
```
Fetch the 1.0.1 chart:
```
helm fetch \
    demo44/wordpress \
    --untar \
    --untardir ./charts/demo44 \
    --version 1.0.1
```
Succeeds

## Remove a chart, to find the inconsistency as well:
```sh
az acr helm delete wordpress --version 1.0.1
helm repo update
helm fetch \
    demo44/wordpress \
    --untar \
    --untardir ./charts/demo44
```
**Error:**

`Error: Failed to fetch https://demo44.azurecr.io/helm/v1/repo/_blobs/wordpress-1.0.1.tgz : 404 Not Found`

```sh
az acr helm repo add
helm fetch \
    demo44/wordpress \
    --untar \
    --untardir ./charts/demo44
```
**Still get the error:**

`Error: Failed to fetch https://demo44.azurecr.io/helm/v1/repo/_blobs/wordpress-1.0.1.tgz : 404 Not Found`

`helm search`, still references the 1.0.1 chart
```sh
helm search demo44/
NAME                    CHART VERSION   APP VERSION     DESCRIPTION
demo44/wordpress        1.0.1           4.9.8           Web publishing platform for building blogs and websites.
```

The only way I could clear this up was:

```sh
helm repo remove demo44
az acr helm repo add
helm search demo44/
NAME                    CHART VERSION   APP VERSION     DESCRIPTION
demo44/wordpress        1.0.0           4.9.8           Web publishing platform for building blogs and websites.
```

**Anything else we need to know?**:
We could tell customers `helm repo update` doesn't work consistently, and they should use `az acr helm repo add`, however that produces inconsistent results

### Pri 0:
- `az acr helm repo add` should resolve the current version and put everything back in sync
- `helm repo update` should do sync the local cache with the server, removing the need to use `az acr helm repo add` just to update the cache

### Pri 1/2
The crux of the issue is the local cache, which is less of a cache, but rather a different "client" that must be synchronized with the server. Would suggest we really contribute to the [proposal to make the client really a passive cache](https://github.com/helm/community/blob/6661a67709f7b92a4ac7a8606a99365c775c6a7d/proposals/helm-repo-container-registry-convergence/001-repo-registry.md), similar to docker images. 

For the purposes of the ACR Scope, we should focus on Pri 0, and work with the community on the helm cache.

**Environment (if applicable to the issue)**: