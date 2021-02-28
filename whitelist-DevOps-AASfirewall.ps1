# Code found on: https://arthur86s.medium.com/how-to-add-your-devops-ip-to-azure-analysis-services-firewall-962652cd5b36
# This is needed to allow the IP address that DevOps is deploying from through the analysis services firewall.

#Author - Arthur Steijn // Motion10 // 20200708
#Original from Mathias Wrobel // Innofactor A/S 

#Other sites to provide IPv4 public address with this type of request

<#
http://ipinfo.io/ip
http://ifconfig.me/ip
http://icanhazip.com
http://ident.me
http://smart-ip.net/myip
#>

# Set Parameters
[CmdletBinding()]
param(
    [Parameter(ValueFromPipeline = $true)][String] $ResourceName = "AnalysisServicesName",
    [Parameter(ValueFromPipeline = $true)][String] $ResourceGroup = "ResourceGroupName"
     )

#Setting additional parameters
$ExistingFirewallRuleName = "AzureDevOps"
$PubIPSource = "ipinfo.io/ip"

$AServiceServer = Get-AzAnalysisServicesServer -Name $ResourceName -ResourceGroupName $ResourceGroup
$FirewallRules = ($AServiceServer).FirewallConfig.FirewallRules
$FirewallRuleNameList = $FirewallRules.FirewallRuleName
$powerBi = ($AServiceServer).FirewallConfig.EnablePowerBIService

#Getting previous IP from firewall rule, and new public IP
$PreviousRuleIndex = [Array]::IndexOf($FirewallRuleNameList, $ExistingFirewallRuleName)
$currentIP = (Invoke-WebRequest -uri $PubIPSource -UseBasicParsing).content.TrimEnd()
$previousIP = ($FirewallRules).RangeStart[$PreviousRuleIndex]

#Updating rules if request is coming from new IP address.
if (!($currentIP -eq $previousIP)) {
    Write-Output "Updating Analysis Service firewall config"
    $ruleNumberIndex = 1
    $Rules = @() -as [System.Collections.Generic.List[Microsoft.Azure.Commands.AnalysisServices.Models.PsAzureAnalysisServicesFirewallRule]]

    #Storing Analysis Service firewall rules
    $FirewallRules | ForEach-Object {
        $ruleNumberVar = "rule" + "$ruleNumberIndex"
        #Exception of storage of firewall rule is made for the rule to be updated
        if (!($_.FirewallRuleName -match "$ExistingFirewallRuleName")) {

            $start = $_.RangeStart
            $end = $_.RangeEnd
            $tempRule = New-AzAnalysisServicesFirewallRule `
                -FirewallRuleName $_.FirewallRuleName `
                -RangeStart $start `
                -RangeEnd $end

            Set-Variable -Name "$ruleNumberVar" -Value $tempRule
            $Rules.Add((Get-Variable $ruleNumberVar -ValueOnly))
            $ruleNumberIndex = $ruleNumberIndex + 1
        }
    }
    
    Write-Output $FirewallRules         #Write all FireWall Rules to Host

    #Add rule for new IP
    $updatedRule = New-AzAnalysisServicesFirewallRule `
        -FirewallRuleName "$ExistingFirewallRuleName" `
        -RangeStart $currentIP `
        -RangeEnd $currentIP
    
    $ruleNumberVar = "rule" + "$ruleNumberIndex"
    Set-Variable -Name "$ruleNumberVar" -Value $updatedRule
    $Rules.Add((Get-Variable $ruleNumberVar -ValueOnly))

    #Creating Firewall config object
    if ($powerBi) {
            $conf = New-AzAnalysisServicesFirewallConfig -EnablePowerBiService -FirewallRule $Rules 
        }
    else {       
            $conf = New-AzAnalysisServicesFirewallConfig -FirewallRule $Rules 
        }
    
    #Setting firewall config
    if ([String]::IsNullOrEmpty($AServiceServer.BackupBlobContainerUri)) {
        $AServiceServer | Set-AzAnalysisServicesServer `
            -FirewallConfig $conf `
            -DisableBackup `
            -Sku $AServiceServer.Sku.Name.TrimEnd()
    }
    else {
        $AServiceServer | Set-AzAnalysisServicesServer `
            -FirewallConfig $conf `
            -BackupBlobContainerUri $AServiceServer.BackupBlobContainerUri `
            -Sku $AServiceServer.Sku.Name.TrimEnd()
    
    }
    Write-Output "Updated firewall rule to include current IP: $currentIP"
    Write-Output "Enable Power Bi Service was set to: $powerBi" 
}
