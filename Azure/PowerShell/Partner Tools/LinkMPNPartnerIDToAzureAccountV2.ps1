## Name     : LinkMPNPartnerIDToAzureAccountV1.ps1
## Author   : Jack Tracey - https://jacktracey.co.uk
## Version  : 2

## *NOTES START*
## This script will gather the MPN ID that you enter and then assign this to the user in the Azure AD tenant you are logged in as.
## This script requires the following modules to be installed: 'Az' & 'Az.ManagementPartner'.
## The script will fail if neither of these modules are installed.
## *NOTES END*

# Creating Log File & Starting Transcript

$DateTime = Get-Date -Format dd-MM-yyyy-HHmm
$LogFileName = 'LinkMPNPartnerIDToAzureAccountV1-Log-' +$DateTime+ '.txt'

$LogFile = New-Item -Name "$LogFileName" -ItemType File -ErrorAction Stop
Start-Transcript -Path $LogFile -ErrorAction Stop

Write-Host "Logging started and will be stored in this file:" $LogFile.FullName -ForegroundColor Yellow
Write-Host ""

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
Write-Host ""
Write-Host "Please enter the customers Azure AD Tenant/Directory ID below, followed by pressing the 'Enter/Return' key:" -ForegroundColor Cyan
$customerAzureADID = Read-Host

Write-Host ""
Write-Host "Azure AD Tenant/Directory ID entered:" $customerAzureADID -ForegroundColor Yellow

# Connect To Azure Account

Write-Host "Logging In To The Azure Management Plane (ARM)..." -ForegroundColor Cyan
Write-Host ""
Write-Host "Please login with the account you wish to link your Partner ID." -ForegroundColor Cyan
Write-Host "This account must have permissions on the customers Azure platform." -ForegroundColor Yellow
Write-Host ""

Connect-AzAccount -TenantId $customerAzureADID -ErrorAction SilentlyContinue
$AzureLoginCheck = Get-AzContext -ErrorAction SilentlyContinue

if ($AzureLoginCheck.Tenant.Id -eq $customerAzureADID) {
    Write-Host "Logged in to Azure Management ARM successfully" -ForegroundColor Green
    Write-Host ""
}
else {
    Write-Host "Login failed to customers Azure platform. This script will now close when any key is pressed. Please rerun the script to try again." -ForegroundColor Red
    Read-Host
    Stop-Transcript
    exit
}

# Collect New MPN Partner ID 

$MPNPartnerID = $null
do {
    Write-Host "Please enter the MPN Partner ID you wish to link this customers Azure too, followed by pressing the 'Enter/Return' key:" -ForegroundColor Cyan
    $MPNPartnerID = Read-Host
} until ($MPNPartnerID -ne "$null")

Write-Host "MPN Partner ID Captured:"$MPNPartnerID -ForegroundColor Green
Write-Host ""

# Collect Azure Existing MPN Partner ID Info

Write-Host "Checking if existing MPN Partner ID is set to any value"
Write-Host ""

$existingMPNPartnerIdInfo = $null

$existingMPNPartnerIdInfo = Get-AzManagementPartner -ErrorAction SilentlyContinue

if ($existingMPNPartnerIdInfo -eq "$null") {
    Write-Host "MPN Partner ID Not Currently Set To Any Value" -ForegroundColor Green
    Write-Host ""
}
else {
    Write-Host "MPN Partner ID already set to:" $existingMPNPartnerIdInfo.PartnerId -ForegroundColor Yellow
    Write-Host "The exisiting MPN Partner name is:" $existingMPNPartnerIdInfo.PartnerName -ForegroundColor Yellow
    Write-Host ""
}

# Check if Azure MPN Partner IDs Are The Same

if ($existingMPNPartnerIdInfo.PartnerId -eq $MPNPartnerID) {
    Write-Host "The MPN Partner ID you wish to set is already set as the MPN Partner ID for this customers Azure Tenant" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "No action is required. This script will close when any key is pressed." -ForegroundColor Green
    Read-Host
    Stop-Transcript
    exit
}
else {
    Write-Host "The MPN Partner ID you wish to set is different to what is already set." -ForegroundColor Red
    Write-Host ""
    Write-Host "The MPN Partner ID you wish to set is:" $MPNPartnerID -ForegroundColor Yellow
    Write-Host "The MPN Partner ID that is currently set is:" $existingMPNPartnerIdInfo.PartnerId -ForegroundColor Yellow
    Write-Host "The MPN Partner name that is currently set are:" $existingMPNPartnerIdInfo.PartnerName -ForegroundColor Yellow
    Write-Host ""
}

# Check If New Azure MPN Partner ID Should Be Set

$setNewMPNPartnerId = 'n'

Write-Host "Do you wish to set/replace the specified MPN Partner ID for this customers Azure Tenant? `nPlease enter 'y' or 'n' followed by the 'Enter/Return' key. (The default is 'n'):" -ForegroundColor Cyan
$setNewMPNPartnerId = Read-Host

if ($setNewMPNPartnerId -eq 'n') {
    Write-Host ""
    Write-Host "You have chosen not to change/set the MPN Partner ID for this customers Azure Tenant." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "The MPN Partner ID will remain set as:" $existingMPNPartnerIdInfo.PartnerId -ForegroundColor Cyan
    Write-Host "Which is for the MPN Partner named:" $existingMPNPartnerIdInfo.PartnerName -ForegroundColor Cyan
    Write-Host ""
    Write-Host "This script will close when any key is pressed." -ForegroundColor Red
    Read-Host
    Stop-Transcript
    exit
}

if ($setNewMPNPartnerId -eq 'y') {
    if ($existingMPNPartnerIdInfo -eq "$null") {
        Write-Host ""
        Write-Host "You have chosen to set the MPN Partner ID for this customers Azure Tenant to:" $MPNPartnerID -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Press the 'Enter/Return' key to set the new MPN Partner ID for this customers Azure Tenant." -ForegroundColor Cyan
        Read-Host
        Write-Host ""
        Write-Host "Setting the MPN Parter ID..." -ForegroundColor Cyan
        New-AzManagementPartner -PartnerId $MPNPartnerID -ErrorAction SilentlyContinue
        Write-Host ""
        Write-Host "MPN Partner ID set!" -ForegroundColor Green
    }
    else {
        Write-Host ""
        Write-Host "You have chosen to update the MPN Partner ID for this customers Azure Tenant to:" $MPNPartnerID -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Press the 'Enter/Return' key to set the new MPN Partner ID for this customers Azure Tenant." -ForegroundColor Cyan
        Read-Host
        Write-Host ""
        Write-Host "Updating the MPN Parter ID..." -ForegroundColor Cyan
        New-AzManagementPartner -PartnerId $MPNPartnerID -ErrorAction SilentlyContinue
        Write-Host ""
        Write-Host "MPN Partner ID Updated!" -ForegroundColor Green
    }
    
}

# Check if New Azure MPN Partner ID Has Been Set Correctly

Write-Host ""
Write-Host "Checking MPN Partner ID set correctly..." -ForegroundColor Cyan
Write-Host ""

$newMPNPartnerIdInfo = $null

$newMPNPartnerIdInfo = Get-AzManagementPartner -ErrorAction SilentlyContinue

if ($newMPNPartnerIdInfo.PartnerId -eq $MPNPartnerID) {
    Write-Host "MPN Partner ID Set Correctly!" -ForegroundColor Green
    Write-Host ""
    Write-Host "MPN Parnter ID currently set to:" $newMPNPartnerIdInfo.PartnerId -ForegroundColor Yellow
    Write-Host "Which is for the MPN Partner named:" $newMPNPartnerIdInfo.PartnerName -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Script complete and will therefore close when any key is pressed" -ForegroundColor Green
    Read-Host
    Stop-Transcript
}
else {
    Write-Host "MPN Partner ID Not Set Correctly. Please Check Log File To Investigate" -ForegroundColor Red
    Write-Host ""
    Write-Host "MPN Parnter ID currently set to:" $newMPNPartnerIdInfo.PartnerId -ForegroundColor Yellow
    Write-Host "Which is for the MPN Partner named:" $newMPNPartnerIdInfo.PartnerName -ForegroundColor Yellow
    Write-Host ""
    Write-Host "This script will now close when any key is pressed" -ForegroundColor Cyan
    Read-Host
    Stop-Transcript 
    exit
}
