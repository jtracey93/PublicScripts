## Name     : LinkPartnerIDAzureAccountsV1.0.ps1
## Author   : Jack Tracey - https://jacktracey.co.uk
## Version  : 1.0

## *NOTES START*
## This script will gather the MPN ID that you enter and then assign this to the user in the Azure AD tenant you are logged in as.
## This script requires the following modules to be installed: 'Az' & 'Az.ManagementPartner'.
## The script will fail if neither of these modules are installed.
## *NOTES END*

# Check Required Modules Are Installed

Write-Host "Checking for required PowerShell modules..." -ForegroundColor Cyan
Write-Host ""

if (Get-InstalledModule -Name 'Az' -ErrorAction SilentlyContinue) {
    Write-Host "Az PowerShell Module Installed" -ForegroundColor Green
    Write-Host ""
}
else {
    Write-Host "Az PowerShell Module NOT Installed" -ForegroundColor Red
    Write-Host "Please install the module, following the instructions listed here:" -ForegroundColor Yellow
    Write-Host "https://docs.microsoft.com/en-us/powershell/azure/install-az-ps" -ForegroundColor Yellow
    Write-Host ""
}

if (Get-InstalledModule -Name 'Az.ManagementPartner' -ErrorAction SilentlyContinue) {
    Write-Host "Az.ManagementPartner PowerShell Module Installed" -ForegroundColor Green
    Write-Host ""
}
else {
    Write-Host "Az.ManagementPartner PowerShell Module NOT Installed" -ForegroundColor Red
    Write-Host "Please install the module, following the instructions listed here:" -ForegroundColor Yellow
    Write-Host "https://www.powershellgallery.com/packages/Az.ManagementPartner" -ForegroundColor Yellow
    Write-Host ""
}

# Collect Tenant ID

Write-Host "For the next step you will require the Azure AD Tenant/Directory ID for the customer you wish to set the Partner ID for." -ForegroundColor Cyan
Write-Host ""
Write-Host "This can be found by following the instructions listed below:" -ForegroundColor Yellow
Write-Host "1 - Login to the customers Azure portal. `n2 - Select the 'Azure Active Directory' blade/console. `n3 - Select 'Properties' from the left hand side menu. `n4 - The 'Directory ID' is the value you require. Copy this value." -ForegroundColor Magenta

Write-Host "Please enter the customers Azure AD Tenant/Directory ID below:" -ForegroundColor Blue
$customerAzureADID = Read-Host

# Connect To Azure Account

Write-Host "Logging In To The Azure Management Plane (ARM)..." -ForegroundColor Cyan
Write-Host ""
Write-Host "Please login with the account you wish to link your Partner ID." -ForegroundColor Blue
Write-Host "This account must have permissions on the customers Azure platform." -ForegroundColor Yellow
Write-Host ""

Connect-AzAccount -TenantId $customerAzureADID -ErrorAction SilentlyContinue
$AzureLoginCheck = Get-AzContext

if ($AzureLoginCheck.Tenant.Id -eq $customerAzureADID) {
    Write-Host "Logged in to Azure Management ARM successfully" -ForegroundColor Green
    Write-Host ""
}
else {
    Write-Host "Login failed to customers Azure platform. This script will now close when any key is pressed. Please rerun the script to try again." -ForegroundColor Red
    Read-Host
    exit
}

# Collect New MPN Partner ID 

$MPNPartnerID = $null
do {
    Write-Host "Please enter the MPN Partner ID you wish to link this customers Azure too:" -ForegroundColor Blue
    $MPNPartnerID = Read-Host
} until ($MPNPartnerID -ne "$null")

Write-Host "MPN Partner ID Captured:"$MPNPartnerID -ForegroundColor Green

# Collect Azure Partner ID Info

Write-Host "Checking if existing MPN Partner ID is set to any value"

$existingMPNPartnerIdInfo = $null

$existingMPNPartnerIdInfo = Get-AzManagementPartner

if ($existingMPNPartnerIdInfo -eq "$null") {
    Write-Host "MPN Partner ID Not Set To Any Value" -ForegroundColor Green
}