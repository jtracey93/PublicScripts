######################
# Wipe-ESLZAzTenant #
######################
# Version: 1.1
# Last Modified: 29/09/2021
# Author: Jack Tracey 
# Contributors: Liam F. O'Neill, Paul Grimley, Jeff Mitchell

<#
.SYNOPSIS
Fully resets an AAD tenant after deploying Enterprise Scale (Azure Landing Zone Accelerator) so it can be deployed again. BEWARE: THIS WILL DELETE ALL OF YOUR AZURE RESOURCES. USE WITH EXTREME CAUTION.

.DESCRIPTION
Fully resets an AAD tenant after deploying Enterprise Scale (Azure Landing Zone Accelerator) so it can be deployed again. BEWARE: THIS WILL DELETE ALL OF YOUR AZURE RESOURCES. USE WITH EXTREME CAUTION.

.EXAMPLE
# Without SPN Removal
.\Wipe-ESLZAzTenant.ps1 -tenantRootGroupID "f73a2b89-6c0e-4382-899f-ea227cd6b68f" -intermediateRootGroupID "Contoso"

# With SPN Removal
.\Wipe-ESLZAzTenant.ps1 -tenantRootGroupID "f73a2b89-6c0e-4382-899f-ea227cd6b68f" -intermediateRootGroupID "Contoso" -eslzAADSPNName = "Contoso-ESLZ-SPN"

.NOTES
Learn more about Enterprise-scale here:
https://github.com/Azure/Enterprise-Scale
https://aka.ms/es/guides

# Required PowerShell Modules:
- https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-6.4.0
- Install-Module -Name Az 
- Specifically 'Az.Accounts', 'Az.Resources' & 'Az.ResourceGraph' if you need to limit what is installed

# Release notes 14/09/2021: 
- Initial release.
- GroupName has been changes to GroupId as per Az PowerShell module warning message 'upcoming breaking changes in the cmdlet 'Get-AzManagementGroup'as documented https://aka.ms/azps-changewarnings'
    - Warnings have been disabled!
- Uses Azure Resource Graph to get list of subscriptions in the Intermediate Root Management Group's hierarchy tree, therefore it can take a few minutes (5/10) for the Resoruce Graph data to refresh and pull all the Subscriptions in the tree, if recently moved between Management Groups 
#>

[CmdletBinding()]
param (
    #Added this back into parameters as error occurs if multiple tenants are found when using Get-AzTenant
    [Parameter(Mandatory = $true, Position = 1, HelpMessage = "Please the Insert Tenant ID (GUID) of your Azure AD tenant e.g.'f73a2b89-6c0e-4382-899f-ea227cd6b68f'")]
    [string]
    $tenantRootGroupID = "<Insert the Tenant ID (GUID) of your Azure AD tenant>",

    [Parameter(Mandatory = $true, Position = 2, HelpMessage = "Insert the name of your intermediate root Management Group e.g. 'Contoso'")]
    [string]
    $intermediateRootGroupID = "<Insert the name of your intermediate root Management Group e.g. Contoso>",

    [Parameter(Mandatory = $false, Position = 3, HelpMessage = "(Optional) Please enter the display name of your Enterprise-scale app registration in Azure AD. If left blank, no app registration is deleted.")]
    [string]
    $eslzAADSPNName = ""
)

#Toggle to stop warnings with regards to DisplayName and DisplayId
Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"

# Start timer
$StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch
$StopWatch.Start()

# Check required PowerShell modules are installed
if ((Get-InstalledModule -Name 'Az' -MinimumVersion '6.3.0' -ErrorAction SilentlyContinue) -or ((Get-InstalledModule -Name 'Az.Accounts' -MinimumVersion '2.5.2' -ErrorAction SilentlyContinue) -and (Get-InstalledModule -Name 'Az.Resources' -MinimumVersion '4.3.0' -ErrorAction SilentlyContinue) -and (Get-InstalledModule -Name 'Az.ResourceGraph' -MinimumVersion '0.7.7' -ErrorAction SilentlyContinue))) {
    Write-Host "Required Az Powershell Modules are installed" -ForegroundColor Green 
} else {
    throw "Required Az Powershell Modules are installed. Required modules are: 'Az' OR 'Az.Accounts' (v2.5.2+), 'Az.Resources' (v4.3.0+) & 'Az.ResourceGraph' (v0.7.7+)"
}

# Get all Subscriptions that are in the Intermediate Root Management Group's hierarchy tree
$intermediateRootGroupChildSubscriptions = Search-AzGraph -Query "resourcecontainers | where type =~ 'microsoft.resources/subscriptions' | mv-expand mgmtGroups=properties.managementGroupAncestorsChain | where mgmtGroups.name =~ '$intermediateRootGroupID' | project subName=name, subID=subscriptionId, subState=properties.state, aadTenantID=tenantId, mgID=mgmtGroups.name, mgDisplayName=mgmtGroups.displayName"

Write-Host "Moving all subscriptions under root management group" -ForegroundColor Yellow

# For each Subscription in Intermediate Root Management Group's hierarchy tree, move it to the Tenant Root Management Group
$intermediateRootGroupChildSubscriptions | ForEach-Object -Parallel {
    # The name 'Tenant Root Group' doesn't work. Instead, use the GUID of your Tenant Root Group
    if ($_.subState -ne "Disabled") {
        Write-Host "Moving Subscription: '$($_.subName)' under Tenant Root Management Group: '$($using:tenantRootGroupID)'" -ForegroundColor Cyan
        New-AzManagementGroupSubscription -GroupId $using:tenantRootGroupID -SubscriptionId $_.subID
    }    
}

# For each Subscription in the Intermediate Root Management Group's hierarchy tree, remove all Resources, Resource Groups and Deployments
Write-Host "Removing all Azure Resources, Resource Groups and Deployments from Subscriptions in scope" -ForegroundColor Yellow

ForEach ($subscription in $intermediateRootGroupChildSubscriptions) {
    Write-Host "Set context to Subscription: '$($subscription.subName)'" -ForegroundColor Cyan
    Set-AzContext -Subscription $subscription.subID | Out-Null

    # Get all Resource Groups in Subscription
    $resources = Get-AzResourceGroup

    $resources | ForEach-Object -Parallel {
        Write-Host "Deleting " $_.ResourceGroupName "..." -ForegroundColor Red
        Remove-AzResourceGroup -Name $_.ResourceGroupName -Force | Out-Null
    }
    
    # Get Deployments for Subscription
    $subDeployments = Get-AzSubscriptionDeployment

    Write-Host "Removing All Subscription Deployments for: $($subscription.subName)" -ForegroundColor Yellow 
    
    # For each Subscription level deployment, remove it
    $subDeployments | ForEach-Object -Parallel {
        Write-Host "Removing $($_.DeploymentName) ..." -ForegroundColor Red
        Remove-AzSubscriptionDeployment -Id $_.Id
    }
}

# Get all AAD Tenant level deployments
$tenantDeployments = Get-AzTenantDeployment

Write-Host "Removing all Tenant level deployments" -ForegroundColor Yellow

# For each AAD Tenant level deployment, remove it
$tenantDeployments | ForEach-Object -Parallel {
    Write-Host "Removing $($_.DeploymentName) ..." -ForegroundColor Red
    Remove-AzTenantDeployment -Id $_.Id
}

# Remove ESLZ SPN, if provided
if ($eslzAADSPNName -ne "") {
    Write-Host "Removing Azure AD Application Registration/SPN:" $eslzAADSPNName -ForegroundColor Red
    Remove-AzADApplication -DisplayName $eslzAADSPNName -Force
}
else {
    Write-Host "No Azure AD Application/SPN was provided. Therefore no Azure AD Application/SPN will be removed." -ForegroundColor Cyan
}

# This function only deletes Management Groups in the Intermediate Root Management Group's hierarchy tree and will NOT delete other Intermediate Root level Management Groups and their children e.g. in the case of "canary"
function Remove-Recursively($name) {
    # Enters the parent Level
    Write-Host "Entering the scope with $name" -ForegroundColor Green
    $parent = Get-AzManagementGroup -GroupId $name -Expand -Recurse

    # Checks if there is any parent level
    if ($null -ne $parent.Children) {
        Write-Host "Found the following Children :" -ForegroundColor Yellow
        Write-host ($parent.Children | Select-Object Name).Name -ForegroundColor White

        foreach ($children in $parent.Children) {
            # Tries to recur to each child item
            Remove-Recursively($children.Name)
        }
    }

    # If no children are found at each scope
    Write-Host "No children found in scope $name" -ForegroundColor Yellow
    Write-Host "Removing the scope $name" -ForegroundColor Red
    
    Remove-AzManagementGroup -InputObject $parent
}

# Remove all the Management Groups in Intermediate Root Management Group's hierarchy tree, including itself
Remove-Recursively($intermediateRootGroupID)

# Stop timer
$StopWatch.Stop()

# Display timer output as table
Write-Host "Time taken to complete task:" -ForegroundColor Yellow
$StopWatch.Elapsed | Format-Table
