# Script to deploy the analysis services model from DevOps pipeline
# L. McConnell (2020 December)
# Code borrowed from S. Swindell

Param (
    $artifactPath,
    [string]$userName,
    [string]$userPassword,
    $serverName,
    $tenantID
)

# read model from the asdatabase file
$model = Get-Content -Path $artifactPath -Raw | ConvertFrom-Json

# generate a TSML command to deploy the model
$commandObject = @{
    createOrReplace = @{
        object = @{
            #name of the database to replace
            database="AW Internet Sales"
        };
        database=$model
    }
}

$command = $commandObject | ConvertTo-Json -Depth 100

# convert to SecureString and create the credentials
[securestring]$secStringPassword = ConvertTo-SecureString $userPassword -AsPlainText -Force
[pscredential]$credObject = New-Object System.Management.Automation.PSCredential ($userName, $secStringPassword)

# import the SQLServer module to use the Invoke-ASCmd cmdlet
Import-Module SQLServer

# run the TSML command
Invoke-ASCmd -Server $serverName -Query $command -Credential $credObject -ServicePrincipal -TenantId $tenantID
