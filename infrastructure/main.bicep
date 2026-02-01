// Main infrastructure template for TravelMeetupApp

@description('Environment name (dev, staging, prod)')
@allowed([
  'dev'
  'staging'
  'prod'
])
param environment string = 'dev'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Application name prefix')
param appNamePrefix string = 'travelmeetup'

@description('SQL Admin username')
@secure()
param sqlAdminUsername string

@description('SQL Admin password')
@secure()
param sqlAdminPassword string

@description('JWT Secret Key')
@secure()
param jwtSecretKey string

@description('JWT Refresh Secret Key')
@secure()
param jwtRefreshSecretKey string

// Variables
var appServicePlanName = '${appNamePrefix}-plan-${environment}'
var webAppName = '${appNamePrefix}-api-${environment}'
var sqlServerName = '${appNamePrefix}-sql-${environment}'
var sqlDatabaseName = '${appNamePrefix}-db-${environment}'
var keyVaultName = '${appNamePrefix}-kv-${environment}'
var appInsightsName = '${appNamePrefix}-ai-${environment}'

// App Service Plan SKU based on environment
var appServicePlanSku = environment == 'prod' ? {
  name: 'S1'
  tier: 'Standard'
  capacity: 1
} : {
  name: 'F1'
  tier: 'Free'
  capacity: 1
}

// SQL Database SKU based on environment
var sqlDatabaseSku = environment == 'prod' ? {
  name: 'S0'
  tier: 'Standard'
} : {
  name: 'Basic'
  tier: 'Basic'
}

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: appServicePlanName
  location: location
  sku: appServicePlanSku
  kind: 'linux'
  properties: {
    reserved: true
  }
  tags: {
    environment: environment
    project: 'TravelMeetupApp'
  }
}

// App Service (Web App)
resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: webAppName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'PYTHON|3.11'
      alwaysOn: environment == 'prod' ? true : false
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      http20Enabled: true
      appSettings: [
        {
          name: 'ENVIRONMENT'
          value: environment
        }
        {
          name: 'DEBUG'
          value: environment == 'dev' ? 'True' : 'False'
        }
        {
          name: 'JWT_ALGORITHM'
          value: 'HS256'
        }
        {
          name: 'ACCESS_TOKEN_EXPIRE_MINUTES'
          value: '15'
        }
        {
          name: 'REFRESH_TOKEN_EXPIRE_DAYS'
          value: '7'
        }
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
      ]
    }
  }
  tags: {
    environment: environment
    project: 'TravelMeetupApp'
  }
}

// SQL Server
resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlAdminUsername
    administratorLoginPassword: sqlAdminPassword
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
  }
  tags: {
    environment: environment
    project: 'TravelMeetupApp'
  }
}

// SQL Database
resource sqlDatabase 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  sku: sqlDatabaseSku
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 2147483648 // 2GB
    catalogCollation: 'SQL_Latin1_General_CP1_CI_AS'
    zoneRedundant: false
  }
  tags: {
    environment: environment
    project: 'TravelMeetupApp'
  }
}

// SQL Firewall Rule - Allow Azure Services
resource sqlFirewallAzure 'Microsoft.Sql/servers/firewallRules@2022-05-01-preview' = {
  parent: sqlServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: webApp.identity.principalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
      }
    ]
  }
  tags: {
    environment: environment
    project: 'TravelMeetupApp'
  }
}

// Key Vault Secrets
resource kvSecretDbConnection 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: keyVault
  name: 'DATABASE-CONNECTION-STRING'
  properties: {
    value: 'mssql+pyodbc://${sqlAdminUsername}:${sqlAdminPassword}@${sqlServer.properties.fullyQualifiedDomainName}:1433/${sqlDatabaseName}?driver=ODBC+Driver+18+for+SQL+Server&Encrypt=yes&TrustServerCertificate=no'
  }
}

resource kvSecretJwt 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: keyVault
  name: 'JWT-SECRET-KEY'
  properties: {
    value: jwtSecretKey
  }
}

resource kvSecretJwtRefresh 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: keyVault
  name: 'JWT-REFRESH-SECRET-KEY'
  properties: {
    value: jwtRefreshSecretKey
  }
}

// Application Insights
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    RetentionInDays: 30
    WorkspaceResourceId: logAnalyticsWorkspace.id
    IngestionMode: 'LogAnalytics'
  }
  tags: {
    environment: environment
    project: 'TravelMeetupApp'
  }
}

// Log Analytics Workspace (required for App Insights)
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: '${appNamePrefix}-logs-${environment}'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
  tags: {
    environment: environment
    project: 'TravelMeetupApp'
  }
}

// Outputs
output webAppName string = webApp.name
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
output keyVaultName string = keyVault.name
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey
output appInsightsConnectionString string = appInsights.properties.ConnectionString

// App Service Configuration (separate resource to avoid circular dependency)
resource webAppConfig 'Microsoft.Web/sites/config@2022-09-01' = {
  parent: webApp
  name: 'appsettings'
  properties: {
    ENVIRONMENT: environment
    DEBUG: environment == 'dev' ? 'True' : 'False'
    DATABASE_URL: '@Microsoft.KeyVault(SecretUri=${keyVault.properties.vaultUri}secrets/DATABASE-CONNECTION-STRING/)'
    JWT_SECRET_KEY: '@Microsoft.KeyVault(SecretUri=${keyVault.properties.vaultUri}secrets/JWT-SECRET-KEY/)'
    JWT_REFRESH_SECRET_KEY: '@Microsoft.KeyVault(SecretUri=${keyVault.properties.vaultUri}secrets/JWT-REFRESH-SECRET-KEY/)'
    JWT_ALGORITHM: 'HS256'
    ACCESS_TOKEN_EXPIRE_MINUTES: '15'
    REFRESH_TOKEN_EXPIRE_DAYS: '7'
    APPINSIGHTS_INSTRUMENTATION_KEY: appInsights.properties.InstrumentationKey
    APPLICATIONINSIGHTS_CONNECTION_STRING: appInsights.properties.ConnectionString
    SCM_DO_BUILD_DURING_DEPLOYMENT: 'true'
  }
  dependsOn: [
    kvSecretDbConnection
    kvSecretJwt
    kvSecretJwtRefresh
  ]
}
