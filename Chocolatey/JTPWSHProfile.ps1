# PowerShell profile script
Import-Module posh-git
Import-Module -Name Terminal-Icons
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/jtracey93.omp.json" | Invoke-Expression

Import-Module PSReadLine

Import-Module "$env:USERPROFILE\.copilot\skills\windows-terminal\WindowsTerminalSkill.psd1"

New-Alias tf terraform.exe -Scope Global -Option AllScope

function gitLogOneline {
    git.exe log --oneline
}
New-Alias -Name glo -Value gitLogOneline -Scope Global -Option AllScope

function gitFetchPrune {
    git.exe fetch -p
}
New-Alias -Name gfp -Value gitFetchPrune -Scope Global -Option AllScope

function gitCheckoutMain {
    git.exe checkout main
}
New-Alias -Name gcom -Value gitCheckoutMain -Scope Global -Option AllScope

function gitMergeMain {
    git.exe merge main
}
New-Alias -Name gmm -Value gitMergeMain -Scope Global -Option AllScope

# Stop GHA Repo Function
$stopGhaFunctionGistUri = 'https://gist.githubusercontent.com/jtracey93/0020922bdb57b28970114288b0ddb12a/raw/3d6b7d2400f801e73ac024e4613c89fa58a9a577/Stop-GHARepo.ps1'
$stopGhaFunctionLocalPath = Join-Path -Path $env:TEMP -ChildPath 'Stop-GHARepo.ps1'

try {
    # Always pull the latest gist to keep the migration helpers current
    $response = Invoke-WebRequest -Uri $stopGhaFunctionGistUri -ErrorAction Stop
    $response.Content | Set-Content -Path $stopGhaFunctionLocalPath -Encoding ascii
    . $stopGhaFunctionLocalPath
    New-Alias -Name "stopgha" -Value Stop-GHARepo -Scope Global -Option AllScope
}
catch {
    Write-Warning "Failed to download or load Stop-GHARepo helpers: $_"
}


# Mig PR tool
$migprScriptUri = 'https://gist.githubusercontent.com/jtracey93/91f6c5da4646f06a04e3a005e06e11a5/raw/0d1d32ea7d9cf3d83373e446b0e84b1e776226ec/migpr.ps1'
$migprLocalPath = Join-Path -Path $env:TEMP -ChildPath 'migpr.ps1'

try {
    # Always pull the latest gist to keep the migration helpers current
    $response = Invoke-WebRequest -Uri $migprScriptUri -ErrorAction Stop
    $response.Content | Set-Content -Path $migprLocalPath -Encoding ascii
    . $migprLocalPath
    New-Alias -Name migpr -Value Invoke-MigPullRequest -Scope Global -Option AllScope
}
catch {
    Write-Warning "Failed to download or load migpr helpers: $_"
}
