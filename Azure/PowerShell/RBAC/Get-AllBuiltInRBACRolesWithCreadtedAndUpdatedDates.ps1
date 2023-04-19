$allRoles = Invoke-AzRestMethod -Method GET -Path '/providers/Microsoft.Authorization/roleDefinitions?api-version=2022-04-01'

$tableOfRoles = $allRoles.content | ConvertFrom-Json | Select-Object -ExpandProperty value | Select-Object @{Name="roleName";Expression={$_.properties.roleName}}, Name, @{Name="Type";Expression={$_.properties.type}}, @{Name="UpdatedOn";Expression={[DateTime]::Parse($_.properties.updatedOn)}}, @{Name="CreatedOn";Expression={[DateTime]::Parse($_.properties.createdOn)}}

Write-Host "Built-In Roles:" -ForegroundColor Cyan
$tableOfRoles | Where-Object {$_.Type -eq "BuiltInRole"} | Sort-Object -Property UpdatedOn -Descending | Format-Table -AutoSize
Write-Host ""
