## Name     : GatherAllSubscriptionsInTenant.ps1
## Author   : Jack Tracey - https://jacktracey.co.uk
## Version  : 1.0

## *NOTES START*
## This PowerShell script will find all subscriptions associated to an Azure AD Tenant.
## This PowerShell script needs to be run by an Azure AD Global Administrator on the Azure AD Tenant you wish to discover the subscriptions for.
## You will need to run the first step of this script and then wait for 30 minutes for the elevated permissions to take effect, you will also need to clear the Azure Context from the PowerShell session and re-authenticate to continue.
## *NOTES END*

## *DISCLAIMER*
## This PowerShell Script is provided as is and is not an official supported script by Microsoft

# Initial Login To Azure - Login as Glboal Admin of AAD Tenant

Write-Host -ForegroundColor Yellow "Login to Azure"
Write-Host -ForegroundColor Cyan "Use an account with Glboal Administrator permissions"
Write-Host

Connect-AzAccount -ErrorAction Stop
Write-Host

Write-Host -ForegroundColor Green "Logged into Azure"
Write-Host

$FirstGlobalAdminUserContext = Get-AzContext
$FirstGlobalAdminUserName = $FirstGlobalAdminUserContext.Account.Id
$FirstGlobalAdminUserTenantID = $FirstGlobalAdminUserContext.Tenant.Id

# Elevate logged in User to Tenant Root Group User Access Administrator RBAC role

Write-Host -ForegroundColor Yellow "Elevating User: $FirstGlobalAdminUserName to User Access Admistrator RBAC role on Azure AD Tenant ID: $FirstGlobalAdminUserTenantID at Tenant Root Management Group Scope"
Invoke-AzRestMethod -Method POST -Path '/providers/Microsoft.Authorization/elevateAccess?api-version=2016-07-01' -ErrorAction Stop
Write-Host -ForegroundColor Green "Elevated $FirstGlobalAdminUserName's RBAC"
Write-Host

# Wait for 30 minutes for RBAC to apply and propogate

Write-Host -ForegroundColor Yellow "Starting 30 minute countdown to allow RBAC to apply fully and propogate to all subscriptions..."
Write-Host

$Minutes = 30
$EndTime = [datetime]::UtcNow.AddMinutes($Minutes)

while (($TimeRemaining = ($EndTime - [datetime]::UtcNow)) -gt 0) {
    Write-Progress -Activity 'Watiting for elevated RBAC permissions to take effect:' -Status 'RBAC Applying & Propgating To All Subscriptions In AAD Tenant' -SecondsRemaining $TimeRemaining.TotalSeconds
    Start-Sleep 1
}

# Wait complete - Logout current user Azure PowerShell session

Write-Host
Write-Host -ForegroundColor Yellow "Logging out current user from Azure PowerShell and clearing context..."
Clear-AzContext -Force -ErrorAction Stop

# Log back into Azure as same users

Write-Host -ForegroundColor Yellow "Login back into Azure"
Write-Host -ForegroundColor Cyan "Use the same user account as used in first login to Azure as part of this script."
Write-Host

Connect-AzAccount -ErrorAction Stop
Write-Host

Write-Host -ForegroundColor Green "Logged into Azure"
Write-Host

$SecondGlobalAdminUserContext = Get-AzContext
$SecondGlobalAdminUserName = $SecondGlobalAdminUserContext.Account.Id
$SecondGlobalAdminUserTenantID = $SecondGlobalAdminUserContext.Tenant.Id

if ($SecondGlobalAdminUserName -ne $FirstGlobalAdminUserName) {
    Write-Host -ForegroundColor Red "The user account used in the first and second parts of this script are different! Stopping script"
    Read-Host -Prompt "Press any key to terminate script..."
}

# Get Current Path And Create File Name For Export

$CurrentWorkingLocation = Get-Location
$SubCSVExportFilePath = $CurrentWorkingLocation.Path
$SubCSVExportFileName = "\Subs-$SecondGlobalAdminUserTenantID-$(Get-Date -f dd-MM-yyyy).csv"
$SubCSVExportCombinedPathName = $SubCSVExportFilePath+$SubCSVExportFileName

# Export Sub Details To CSV

Get-AzSubscription | Export-Csv -Path $SubCSVExportCombinedPathName

Write-Host
Write-Host -ForegroundColor Green "Subscription List Exported To CSV For Azure AD Tenant With ID Of: $SecondGlobalAdminUserTenantID To $SubCSVExportFilePath With File Name Of: $SubCSVExportFileName"

# Remove Elevated RBAC Role Assignments

Write-Host -ForegroundColor Yellow "Removing $SecondGlobalAdminUserName's Elevated RBAC Role from Azure AD Tenant ID: $SecondGlobalAdminUserTenantID"
Write-Host

Remove-AzRoleAssignment -SignInName $SecondGlobalAdminUserName -Scope "/" -RoleDefinitionName "User Access Administrator" -ErrorAction Stop

Write-Host
Write-Host -ForegroundColor Green "Removed Elevated RBAC Assignment From $SecondGlobalAdminUserName"
Write-Host
Read-Host -Prompt "Script End. Press Enter Key To Exit..."
