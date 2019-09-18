## Name     : LinkPartnerIDAzureAccountsV1.0.ps1
## Author   : Jack Tracey - https://jacktracey.co.uk
## Version  : 1.0

## *NOTES START*
## This script will gather the MPN ID that you enter and then assign this to the user in the Azure AD tenant you are logged in as.
## This script requires the following modules to be installed: 'Az', 'AzureAD' & 'Az.ManagementPartner'.
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

if (Get-InstalledModule -Name 'AzureAD' -ErrorAction SilentlyContinue) {
    Write-Host "AzureAD PowerShell Module Installed" -ForegroundColor Green
    Write-Host ""
}
else {
    Write-Host "AzureAD PowerShell Module NOT Installed" -ForegroundColor Red
    Write-Host "Please install the module, following the instructions listed here:" -ForegroundColor Yellow
    Write-Host "https://docs.microsoft.com/en-us/powershell/azure/active-directory/install-adv2" -ForegroundColor Yellow
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

# Connect To Azure Account

Write-Host "Login To Azure Management (ARM)..." -ForegroundColor Cyan
Write-Host "Please login with the account you wish to link your Partner ID"

Connect-AzAccount -ErrorAction SilentlyContinue
$AzureLoginCheck = Get-AzContext -ListAvailable

if ($AzureLoginCheck -eq "$null") {
    Write-Host "Logged in to Azure Management ARM successfully" -ForegroundColor Green
    Write-Host ""
}
else {
    Write-Host "Login failed to Azure. This script will now close when any key is pressed. Please rerun the script to try again." -ForegroundColor Red
    Read-Host
    exit
}

# Connect To AzureAD

Write-Host "Login To Azure AD ..." -ForegroundColor Cyan
Write-Host "Please login with the same account as you used previously."

Connect-AzureAD -ErrorAction SilentlyContinue
$AzureADLoginCheck = Get-AzContext -ListAvailable

if ($AzureADLoginCheck -eq "$null") {
    Write-Host "Logged in to Azure AD successfully" -ForegroundColor Green
    Write-Host ""
}
else {
    Write-Host "Login failed to Azure AD. This script will now close when any key is pressed. Please rerun the script to try again." -ForegroundColor Red
    Read-Host
    exit
}