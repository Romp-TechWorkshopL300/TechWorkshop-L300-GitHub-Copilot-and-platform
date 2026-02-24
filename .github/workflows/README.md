# GitHub Actions Deployment Setup

This repository contains a GitHub Actions workflow that builds and deploys the ZavaStorefront .NET application to Azure App Service using OIDC (workload identity federation) for authentication.

## Prerequisites

Configure the following GitHub secrets and variables before running the workflow.

### Azure Setup (OIDC / Workload Identity Federation)

1. Create an Entra ID app registration:

```bash
az ad app create --display-name "github-actions-oidc-TechWorkshop-L300" --query "appId" -o tsv
```

2. Create a service principal for the app:

```bash
az ad sp create --id <app-id>
```

3. Add federated credentials for the GitHub repo (main branch and pull requests):

```bash
# For main branch pushes
az ad app federated-credential create --id <app-object-id> --parameters '{
  "name": "github-actions-main",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:<org>/<repo>:ref:refs/heads/main",
  "audiences": ["api://AzureADTokenExchange"]
}'

# For pull requests
az ad app federated-credential create --id <app-object-id> --parameters '{
  "name": "github-actions-pr",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:<org>/<repo>:pull_request",
  "audiences": ["api://AzureADTokenExchange"]
}'
```

4. Assign the **Contributor** role on the resource group:

```bash
az role assignment create \
  --assignee <app-id> \
  --role Contributor \
  --scope /subscriptions/{subscription-id}/resourceGroups/{resource-group-name}
```

### Required Secrets

| Name | Description |
|------|-------------|
| `AZURE_CLIENT_ID` | App registration (client) ID |
| `AZURE_TENANT_ID` | Entra ID tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID |

### Required Variables

| Name | Description |
|------|-------------|
| `AZURE_APP_SERVICE_NAME` | Azure App Service name |
| `AZURE_RESOURCE_GROUP` | Azure resource group name |

### How to Configure

1. Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions**.
2. Under the **Secrets** tab, add `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, and `AZURE_SUBSCRIPTION_ID`.
3. Under the **Variables** tab, add `AZURE_APP_SERVICE_NAME` and `AZURE_RESOURCE_GROUP`.

## Workflow Triggers

- **Push** to `main` (when files in `src/` change)
- **Pull request** to `main`
- **Manual** via the Actions tab (`workflow_dispatch`)
