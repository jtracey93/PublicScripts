## Name     : ApplyTagsAllResourceTypesInResourceGroupV1.0.ps1
## Author   : Jack Tracey - https://jacktracey.co.uk
## Version  : 1.0

## *NOTES START*
## This script will gather tag name and values to create and add them to a PowerShell hash table variable.
## It will then apply them to specififed resource types within a resource group.
## Existing tags are also kept in tact if a resource already has tags present.
## *NOTES END*

# Gather Azure Required Information
$RSGName = $null
do {
    Write-Host "Please enter the the name of the Resource Group you wish to apply the tags you will specify later to." 
    Write-Host "If this has reappared, you have not entered an input." -ForegroundColor Red
    $RSGName = Read-Host -Prompt 'Resource Group Name'
    Write-Host "" 
} until ($RSGName)

$ResourceType = $null
do {
    Write-Host ""
    Write-Host "Please enter the the name of the Resource Type you wish to apply the tags you will specify later to."
    Write-Host "If this has reappared, you have not entered an input." -ForegroundColor Red
    Write-Host  "EXAMPLE: Microsoft.Compute/virtualMachines" -ForegroundColor Blue
    Write-Host  -NoNewLine "Use this PS command to find Resource Type for all resources:" 
    Write-Host " Get-AzResource | FT" -ForegroundColor Blue
    $ResourceType = Read-Host -Prompt 'Resource Type'
} until ($ResourceType -match "/")

# Create Hash Table Variable
$TagsHashTable = @{}

# Gather Tag Names, Values Loop & Append To Hash Table Variable
Write-Host ""
Write-Host "Specify Tags:"

$AddAnotherTag = 'y'

do {
    Write-Host ""
    $TagName = $null
    $TagValue = $null

    $TagName = Read-Host -Prompt 'Enter Tag Name'
    Write-Host ""

    $TagValue = Read-Host -Prompt 'Enter Tag Value'

    $TagsHashTable.Add($TagName, $TagValue)
    Write-Host ""

    Write-Host "Do you want to add another tag?"
    $AddAnotherTag = Read-Host -Prompt 'Please Enter: y or n (case sensitive)'
} until ($AddAnotherTag -eq "n")

Write-Host "Gathering All Resources To Apply Tags To...."
Write-Host ""

$ResourcesWithoutTags = Get-AzResource -ResourceGroupName $RSGName -ResourceType $ResourceType | where {$_.Tags.Count -eq 0}

$ResourcesWithTags = Get-AzResource -ResourceGroupName $RSGName -ResourceType $ResourceType | where {$_.Tags.Count -ge 1}

Write-Host "Now Applying Tags To Specified Resource Types In Specified Resource Group. No Existing Tags Will Be Affected."

foreach ($R in $ResourcesWithoutTags) {
    Set-AzResource -Tag $TagsHashTable -ResourceGroupName $RSGName -ResourceType $ResourceType -ResourceName $R.Name -Force 
}

foreach ($R in $ResourcesWithTags) {
    ## Get current resource tags
    $CurrentResourceTags = @{}
    $duplicates = $null
    $item = $null
    $TagsHashTableClone = $TagsHashTable

    $CurrentResourceTags = Get-AzResource -ResourceGroupName $RSGName -ResourceType $ResourceType -ResourceName $R.Name | select Tags
    
    $CurrentResourceTagsHashTable = $CurrentResourceTags.Tags

    $duplicates =  $CurrentResourceTagsHashTable.Keys | where {$TagsHashTableClone.ContainsKey($_)}
    
    ## Look for duplicate tag key-value pairs and remove them from tags to add
    if ($duplicates) {
    foreach ($item in $duplicates) {
            $TagsHashTableClone.Remove($item)
            }
    }

    $NoDuplicatesHashTable = $CurrentResourceTagsHashTable+$TagsHashTableClone

    Set-AzResource -Tag $NoDuplicatesHashTable -ResourceGroupName $RSGName -ResourceType $ResourceType -ResourceName $R.Name -Force 
  
}

Write-Host "Tags Applied Successfully" -ForegroundColor Green

Read-Host -Prompt 'Press Enter To Close...'
