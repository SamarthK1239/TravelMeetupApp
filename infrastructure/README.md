# TravelMeetupApp Infrastructure

This directory contains the Infrastructure as Code (IaC) templates for deploying the TravelMeetupApp backend to Azure using Bicep.

## Prerequisites

- **Azure CLI** - [Install Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- **Bicep CLI** - Usually comes with Azure CLI, but you can install separately: `az bicep install`
- **Azure Subscription** - Active Azure subscription with contributor access
- **Secrets Key Vault** - Pre-configured Key Vault with deployment secrets (see Initial Setup below)

## Architecture

The Bicep template deploys the following Azure resources:

- **App Service Plan** - Linux-based hosting for Python app (B1 for dev, S1 for prod)
- **App Service** - Web app with Python 3.11 runtime
- **Azure SQL Server** - Managed SQL Server instance
- **Azure SQL Database** - Database with appropriate SKU per environment
- **Key Vault** - Stores connection strings and JWT secrets
- **Application Insights** - Monitoring and telemetry
- **Log Analytics Workspace** - Backend for Application Insights

## Files

- `main.bicep` - Main infrastructure template
- `parameters.dev.json` - Development environment parameters
- `parameters.prod.json` - Production environment parameters
- `README.md` - This file

## Initial Setup (One-Time)

Before deploying the main infrastructure, you need to create a secrets Key Vault to store sensitive deployment parameters.

### Step 1: Login to Azure

```powershell
# Login to Azure
az login

# Set your subscription (if you have multiple)
az account set --subscription "Your Subscription Name"

# Verify current subscription
az account show
```

### Step 2: Create Secrets Resource Group and Key Vault

```powershell
# Create resource group for secrets
az group create `
  --name travelmeetup-secrets-rg `
  --location eastus

# Create Key Vault for storing deployment secrets
az keyvault create `
  --name travelmeetup-secrets-kv `
  --resource-group travelmeetup-secrets-rg `
  --location eastus `
  --enable-rbac-authorization false
```

### Step 3: Generate and Store Secrets

```powershell
# Store SQL admin username
az keyvault secret set `
  --vault-name travelmeetup-secrets-kv `
  --name sql-admin-username `
  --value "sqladmin"

# Generate and store strong SQL admin password
# Replace with your own secure password
az keyvault secret set `
  --vault-name travelmeetup-secrets-kv `
  --name sql-admin-password `
  --value "YourSecurePassword123!"

# Generate random JWT secrets (or use your own)
# For Windows PowerShell, you can generate random strings:
# $jwtSecret = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | ForEach-Object {[char]$_})

# Store JWT secret for dev
az keyvault secret set `
  --vault-name travelmeetup-secrets-kv `
  --name jwt-secret-dev `
  --value "your-jwt-secret-key-for-dev-at-least-32-chars-change-this"

# Store JWT refresh secret for dev
az keyvault secret set `
  --vault-name travelmeetup-secrets-kv `
  --name jwt-refresh-secret-dev `
  --value "your-jwt-refresh-secret-key-for-dev-at-least-32-chars-change-this"

# Store JWT secret for prod (use different values!)
az keyvault secret set `
  --vault-name travelmeetup-secrets-kv `
  --name jwt-secret-prod `
  --value "your-jwt-secret-key-for-prod-at-least-32-chars-change-this-different"

# Store JWT refresh secret for prod
az keyvault secret set `
  --vault-name travelmeetup-secrets-kv `
  --name jwt-refresh-secret-prod `
  --value "your-jwt-refresh-secret-key-for-prod-at-least-32-chars-change-this-different"
```

### Step 4: Update Parameter Files

Get your subscription ID:

```powershell
az account show --query id --output tsv
```

Update `parameters.dev.json` and `parameters.prod.json` files:
- Replace `{subscription-id}` with your actual subscription ID
- Verify the Key Vault resource ID matches your secrets Key Vault

### Step 5: Grant Yourself Access to Key Vault

```powershell
# Get your user object ID
$userObjectId = az ad signed-in-user show --query id --output tsv

# Grant yourself access to read secrets during deployment
az keyvault set-policy `
  --name travelmeetup-secrets-kv `
  --object-id $userObjectId `
  --secret-permissions get list
```

## Deployment

### Validate Template

Before deploying, validate the Bicep template:

```powershell
# Create resource group
az group create `
  --name travelmeetup-rg-dev `
  --location eastus

# Validate template
az deployment group validate `
  --resource-group travelmeetup-rg-dev `
  --template-file main.bicep `
  --parameters parameters.dev.json
```

### Preview Changes (What-If)

See what resources will be created/modified without actually deploying:

```powershell
az deployment group what-if `
  --resource-group travelmeetup-rg-dev `
  --template-file main.bicep `
  --parameters parameters.dev.json
```

### Deploy to Development

```powershell
# Create resource group (if not already created)
az group create `
  --name travelmeetup-rg-dev `
  --location eastus

# Deploy infrastructure
az deployment group create `
  --resource-group travelmeetup-rg-dev `
  --template-file main.bicep `
  --parameters parameters.dev.json `
  --verbose
```

### Deploy to Production

```powershell
# Create production resource group
az group create `
  --name travelmeetup-rg-prod `
  --location eastus

# Validate production deployment
az deployment group validate `
  --resource-group travelmeetup-rg-prod `
  --template-file main.bicep `
  --parameters parameters.prod.json

# Preview production changes
az deployment group what-if `
  --resource-group travelmeetup-rg-prod `
  --template-file main.bicep `
  --parameters parameters.prod.json

# Deploy to production
az deployment group create `
  --resource-group travelmeetup-rg-prod `
  --template-file main.bicep `
  --parameters parameters.prod.json `
  --verbose
```

### View Deployment Outputs

After deployment, view the outputs:

```powershell
az deployment group show `
  --resource-group travelmeetup-rg-dev `
  --name main `
  --query properties.outputs
```

Outputs include:
- `webAppName` - Name of the App Service
- `webAppUrl` - URL of the deployed web app
- `sqlServerFqdn` - Fully qualified domain name of SQL Server
- `keyVaultName` - Name of the Key Vault
- `appInsightsInstrumentationKey` - Application Insights instrumentation key

## GitHub Actions Setup

To enable automated deployment via GitHub Actions:

### Step 1: Create Service Principal

```powershell
# For dev environment
az ad sp create-for-rbac `
  --name "github-actions-travelmeetup-dev" `
  --role contributor `
  --scopes /subscriptions/{subscription-id}/resourceGroups/travelmeetup-rg-dev `
  --sdk-auth

# For prod environment (separate permissions)
az ad sp create-for-rbac `
  --name "github-actions-travelmeetup-prod" `
  --role contributor `
  --scopes /subscriptions/{subscription-id}/resourceGroups/travelmeetup-rg-prod `
  --sdk-auth
```

### Step 2: Grant Service Principal Access to Secrets Key Vault

```powershell
# Get the service principal object ID
$spObjectId = az ad sp list --display-name "github-actions-travelmeetup-dev" --query "[0].id" --output tsv

# Grant read access to secrets Key Vault
az keyvault set-policy `
  --name travelmeetup-secrets-kv `
  --object-id $spObjectId `
  --secret-permissions get list
```

### Step 3: Add GitHub Secrets

1. Go to your GitHub repository
2. Navigate to Settings > Secrets and variables > Actions
3. Add the following secrets:
   - `AZURE_CREDENTIALS` - The JSON output from the service principal creation
   - `AZURE_WEBAPP_PUBLISH_PROFILE_DEV` - Download from Azure Portal (App Service > Deployment Center)
   - `AZURE_WEBAPP_PUBLISH_PROFILE_PROD` - Download from Azure Portal (App Service > Deployment Center)

## Managing Infrastructure

### Update Infrastructure

Make changes to `main.bicep` and re-run the deployment command. Bicep will only update changed resources.

### Delete Environment

```powershell
# Delete development environment
az group delete --name travelmeetup-rg-dev --yes --no-wait

# Delete production environment
az group delete --name travelmeetup-rg-prod --yes --no-wait
```

**Note:** This is useful for dev environments to save costs when not in use.

### View Resources

```powershell
# List all resources in resource group
az resource list --resource-group travelmeetup-rg-dev --output table
```

### Cost Estimation

**Development Environment:**
- App Service Plan (B1): ~$13/month
- Azure SQL Database (Basic): ~$5/month
- Key Vault: ~$0.03/month
- Application Insights: ~$0-2/month (first 5GB free)
- **Total: ~$18-20/month**

**Production Environment:**
- App Service Plan (S1): ~$69/month
- Azure SQL Database (S0): ~$15/month
- Key Vault: ~$0.03/month
- Application Insights: ~$2-5/month
- **Total: ~$86-90/month**

## Troubleshooting

### Common Issues

**Issue: "Cannot find Key Vault secret"**
- Verify the subscription ID in parameter files is correct
- Ensure you have access to read secrets from the secrets Key Vault
- Check that secret names match exactly (case-sensitive)

**Issue: "Deployment validation failed"**
- Run `az bicep build --file main.bicep` to check for syntax errors
- Ensure all required parameters are provided
- Verify Azure CLI is logged in: `az account show`

**Issue: "Key Vault name already exists"**
- Key Vault names must be globally unique
- Change `appNamePrefix` in parameters file to something unique

**Issue: "SQL Server name already exists"**
- SQL Server names must be globally unique
- Change `appNamePrefix` in parameters file to something unique

### Debugging Deployments

```powershell
# View deployment operations
az deployment group operation list `
  --resource-group travelmeetup-rg-dev `
  --name main

# View specific deployment details
az deployment group show `
  --resource-group travelmeetup-rg-dev `
  --name main
```

## Additional Resources

- [Azure Bicep Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [Azure App Service Documentation](https://learn.microsoft.com/en-us/azure/app-service/)
- [Azure SQL Database Documentation](https://learn.microsoft.com/en-us/azure/azure-sql/)
- [Azure Key Vault Documentation](https://learn.microsoft.com/en-us/azure/key-vault/)

## Support

For issues related to the TravelMeetupApp infrastructure, please open an issue in the GitHub repository.
