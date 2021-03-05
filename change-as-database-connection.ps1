# Script to change analysis services model database connection to prod
# L. McConnell (2021 March)

Param (
  [string]$userName,
  [string]$userPassword,
  $serverName,
  $tenantID,
  $SQLPassword
)

[securestring]$secStringPassword = ConvertTo-SecureString $userPassword -AsPlainText -Force
[pscredential]$credObject = New-Object System.Management.Automation.PSCredential ($userName, $secStringPassword)

Import-Module SQLServer

$query =
@"
{
    "createOrReplace": {
        "object": {
            "database": "WhiteWilson2",
            "dataSource": "SqlServer sqlWWMCPoC DW2"
        },
        "dataSource":
        {
        "type": "structured",
        "name": "SqlServer sqlWWMCPoC DW2",
        "connectionDetails": {
          "protocol": "tds",
          "address": {
            "server": "wwmcsql.southcentralus.cloudapp.azure.com",
            "database": "DW2"
          },
          "authentication": null,
          "query": null
        },
        "options": {},
        "credential": {
          "AuthenticationKind": "UsernamePassword",
          "Username": "thinkdata1",
          "Password": "$($SQLPassword)",
          "EncryptConnection": true,
          "PrivacySetting": "Private"
        }
      }
    }
}
"@

Invoke-ASCmd -Server $ServerName -Credential $credObject -TenantID $tenantID -ServicePrincipal -Query $query
