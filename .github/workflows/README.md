# GitHub Actions Deployment Setup

This repository contains a GitHub Actions workflow that builds and deploys the ZavaStorefront .NET application as a container to Azure App Service.

## Prerequisites

Configure the following GitHub secrets and variables before running the workflow.

### Required Secret

| Name | Description |
|------|-------------|
| `AZURE_CREDENTIALS` | Azure service principal credentials (JSON) |

Create the service principal:

```bash
az ad sp create-for-rbac --name "github-actions-sp" \
  --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group-name} \
  --json-auth
```

Copy the entire JSON output and save it as the `AZURE_CREDENTIALS` secret.

The service principal also needs **AcrPush** on your container registry:

```bash
az role assignment create \
  --assignee {service-principal-client-id} \
  --role AcrPush \
  --scope /subscriptions/{subscription-id}/resourceGroups/{resource-group-name}/providers/Microsoft.ContainerRegistry/registries/{acr-name}
```

### Required Variables

| Name | Description |
|------|-------------|
| `AZURE_CONTAINER_REGISTRY_NAME` | ACR name (without `.azurecr.io`) |
| `AZURE_APP_SERVICE_NAME` | Azure App Service name |

### How to Configure

1. Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions**.
2. Under the **Secrets** tab, add `AZURE_CREDENTIALS`.
3. Under the **Variables** tab, add `AZURE_CONTAINER_REGISTRY_NAME` and `AZURE_APP_SERVICE_NAME`.

## Workflow Triggers

- **Push** to `main` (when files in `src/` change)
- **Pull request** to `main`
- **Manual** via the Actions tab (`workflow_dispatch`)
