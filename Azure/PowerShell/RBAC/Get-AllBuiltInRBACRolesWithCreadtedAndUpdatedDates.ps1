$allRoles = Invoke-AzRestMethod -Method GET -Path '/providers/Microsoft.Authorization/roleDefinitions?api-version=2022-04-01'
$tableofRoles = $allRoles.content | ConvertFrom-Json | Select-Object -ExpandProperty value | Select-Object @{Name="roleName";Expression={$_.properties.roleName}}, Name, @{Name="UpdatedOn";Expression={[DateTime]::Parse($_.properties.updatedOn)}}, @{Name="CreatedOn";Expression={[DateTime]::Parse($_.properties.createdOn)}}
$tableofRoles | Sort-Object -Property UpdatedOn -Descending | Format-Table -AutoSize
