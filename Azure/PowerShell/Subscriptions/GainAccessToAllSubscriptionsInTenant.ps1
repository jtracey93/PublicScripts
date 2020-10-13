## Name     : GainAccessToAllSubscriptionsInTenant.ps1
## Author   : Jack Tracey - https://jacktracey.co.uk
## Version  : 1.0

## *NOTES START*
## This PowerShell script will grant an account, entered during the script runtime, Owner RBAC permission's to the Root Management Group in an Azure AD Tenant - Scope '/'.
## The script will also enable Management Groups on the Azure AD Tenant if they are note already enabled!
## This PowerShell script needs to be run by an Azure AD Global Administrator on the Azure AD Tenant you wish to discover the subscriptions for.
## You will need to run the first step of this script and then wait for 15 minutes for the elevated permissions to take effect, you will also need to clear the Azure Context from the PowerShell session and re-authenticate to continue.
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

# Wait for 15 minutes for RBAC to apply and propogate

Write-Host -ForegroundColor Yellow "Starting 15 minute countdown to allow RBAC to apply fully and propogate to all subscriptions..."
Write-Host

$Minutes = 15
$EndTime = [datetime]::UtcNow.AddMinutes($Minutes)

while (($TimeRemaining = ($EndTime - [datetime]::UtcNow)) -gt 0) {
    Write-Progress -Activity 'Watiting for elevated RBAC permissions to take effect:' -Status 'RBAC Applying & Propgating To All Subscriptions In AAD Tenant' -SecondsRemaining $TimeRemaining.TotalSeconds
    Start-Sleep 1
}

# Wait complete - Logout current user Azure PowerShell session

Write-Host
Write-Host -ForegroundColor Yellow "Logging out current user from Azure PowerShell and clearing context..."
Clear-AzContext -Force -ErrorAction Stop

# Log back into Azure as same user

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

## Gather user to add with permissions over all Azure Subscriptions within the Azure AD Tenant
$UserToAddToAllSubs = Read-Host -Prompt "Please enter the UPN for the user you wish to grant Owner and User Access Administrator over all Azure Subscriptions in this Azure AD Tenant (e.g. user.name@domainname.co.uk)"

## Check for Root Management Group

$RootManagementGroup =  Get-AzManagementGroup | Where-Object {$_.DisplayName -eq "Root Management Group"}

if ($RootManagementGroup -eq $null) {
    Write-Host -ForegroundColor DarkRed "Root Management Group does not exist, this suggests Management Groups have not been enabled on this Azure AD Tenant."
    Write-Host -ForegroundColor Yellow "Now enabling Managmenet Groups on this Azure AD Tenant and creating a default Management Group"
    
    $ManagementGroupId = New-Guid
    New-AzManagementGroup -DisplayName 'Default' -GroupId $ManagementGroupId.Guid -ErrorAction Stop
    
    New-AzRoleAssignment -SignInName $UserToAddToAllSubs -RoleDefinitionName 'Owner' -Scope '/' -ErrorAction Stop
    New-AzRoleAssignment -SignInName $UserToAddToAllSubs -RoleDefinitionName 'User Access Administrator' -Scope '/' -ErrorAction SilentlyContinue
}
else {
    Write-Host -ForegroundColor Green "Root Management Group does exist, will now add permissions at this scope to enable inheritance to all Azure Subscriptions in this Azure AD Tenant."
    New-AzRoleAssignment -SignInName $UserToAddToAllSubs -RoleDefinitionName 'Owner' -Scope '/' -ErrorAction Stop
    New-AzRoleAssignment -SignInName $UserToAddToAllSubs -RoleDefinitionName 'User Access Administrator' -Scope '/' -ErrorAction SilentlyContinue
}

# Remove Elevated RBAC Role Assignments

Write-Host -ForegroundColor Yellow "Removing $SecondGlobalAdminUserName's Elevated RBAC Role from Azure AD Tenant ID: $SecondGlobalAdminUserTenantID"
Write-Host

Remove-AzRoleAssignment -SignInName $SecondGlobalAdminUserName -Scope "/" -RoleDefinitionName "User Access Administrator" -ErrorAction Stop

Write-Host
Write-Host -ForegroundColor Green "Removed Elevated RBAC Assignment From $SecondGlobalAdminUserName"
Write-Host
Read-Host -Prompt "Script End. Press Enter Key To Exit..."
