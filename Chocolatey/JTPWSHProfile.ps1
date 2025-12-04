function ghcs {
    # Debug support provided by common PowerShell function parameters, which is natively aliased as -d or -db
    # https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_commonparameters?view=powershell-7.4#-debug
    param(
        [ValidateSet('gh', 'git', 'shell')]
        [Alias('t')]
        [String]$Target = 'shell',

        [Parameter(Position = 0, ValueFromRemainingArguments)]
        [string]$Prompt
    )
    begin {
        # Create temporary file to store potential command user wants to execute when exiting
        $executeCommandFile = New-TemporaryFile

        # Store original value of GH_DEBUG environment variable
        $envGhDebug = $Env:GH_DEBUG
    }
    process {
        if ($PSBoundParameters['Debug']) {
            $Env:GH_DEBUG = 'api'
        }

        gh copilot suggest -t $Target -s "$executeCommandFile" $Prompt
    }
    end {
        # Execute command contained within temporary file if it is not empty
        if ($executeCommandFile.Length -gt 0) {
            # Extract command to execute from temporary file
            $executeCommand = (Get-Content -Path $executeCommandFile -Raw).Trim()

            # Insert command into PowerShell up/down arrow key history
            [Microsoft.PowerShell.PSConsoleReadLine]::AddToHistory($executeCommand)

            # Insert command into PowerShell history
            $now = Get-Date
            $executeCommandHistoryItem = [PSCustomObject]@{
                CommandLine        = $executeCommand
                ExecutionStatus    = [Management.Automation.Runspaces.PipelineState]::NotStarted
                StartExecutionTime = $now
                EndExecutionTime   = $now.AddSeconds(1)
            }
            Add-History -InputObject $executeCommandHistoryItem

            # Execute command
            Write-Host "`n"
            Invoke-Expression $executeCommand
        }
    }
    clean {
        # Clean up temporary file used to store potential command user wants to execute when exiting
        Remove-Item -Path $executeCommandFile

        # Restore GH_DEBUG environment variable to its original value
        $Env:GH_DEBUG = $envGhDebug
    }
}

function ghce {
    # Debug support provided by common PowerShell function parameters, which is natively aliased as -d or -db
    # https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_commonparameters?view=powershell-7.4#-debug
    param(
        [Parameter(Position = 0, ValueFromRemainingArguments)]
        [string[]]$Prompt
    )
    begin {
        # Store original value of GH_DEBUG environment variable
        $envGhDebug = $Env:GH_DEBUG
    }
    process {
        if ($PSBoundParameters['Debug']) {
            $Env:GH_DEBUG = 'api'
        }

        gh copilot explain $Prompt
    }
    clean {
        # Restore GH_DEBUG environment variable to its original value
        $Env:GH_DEBUG = $envGhDebug
    }
}

Import-Module posh-git
Import-Module -Name Terminal-Icons
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/jtracey93.omp.json" | Invoke-Expression

Import-Module PSReadLine

New-Alias wipealz D:\GitRepos\GitHub-jtracey93\PublicScripts\Azure\PowerShell\Enterprise-scale\Wipe-ESLZAzTenant.ps1 -Scope Global -Option AllScope
New-Alias tf terraform.exe -Scope Global -Option AllScope

function gitLogOneline {
    git.exe log --oneline
}
New-Alias -Name glo -Value gitLogOneline -Scope Global -Option AllScope

# Stops all waiting, in progress, and queued GitHub Action workflows (by default) on a given repository.
function Stop-GHARepo {
    [CmdletBinding()]
    param (
        [String]$repo,
        [bool]$waiting = $true,
        [bool]$inProgress = $true,
        [bool]$queued = $true
    )

    if ($null -eq $repo) {
        $repo = Read-Host -Prompt "Please enter the GitHub Org and Repo you wish to cancel waiting jobs on, e.g. 'Azure/terraform-azurerm-avm-ptn-network-private-link-private-dns-zones'"
    }

    $statesToCancel = @()

    if ($waiting) {
        $statesToCancel += 'waiting'
    }
    if ($inProgress) {
        $statesToCancel += 'in_progress'
    }
    if ($queued) {
        $statesToCancel += 'queued'
    }

    $statesToCancelString = $statesToCancel -join ', '
    $confirmation = Read-Host -Prompt "You are about to cancel all GitHub Actions runs in the following states: [$($statesToCancelString)] on the repo: '$($repo)'. Are you sure you want to proceed? (Y/N)"
    if ($confirmation -ne 'Y' -and $confirmation -ne 'y') {
        throw 'Operation cancelled by user.'
    }

    if ($waiting) {
        Write-Host "Fetching waiting jobs for $($repo)"
        $runsWaiting = gh run list -R $repo -s waiting -L 500 --json databaseId
        $runsWaitingConverted = $runsWaiting | ConvertFrom-Json
    }

    if ($inProgress) {
        Write-Host "Fetching in progress jobs for $($repo)"
        $runsInProgress = gh run list -R $repo -s in_progress -L 500 --json databaseId
        $runsInProgressConverted = $runsInProgress | ConvertFrom-Json
    }

    if ($queued) {
        Write-Host "Fetching queued jobs for $($repo)"
        $runsQueued = gh run list -R $repo -s queued -L 500 --json databaseId
        $runsQueuedConverted = $runsQueued | ConvertFrom-Json
    }

    $runsConverted = @()
    if ($waiting) {
        $runsConverted += $runsWaitingConverted
    }
    if ($inProgress) {
        $runsConverted += $runsInProgressConverted
    }
    if ($queued) {
        $runsConverted += $runsQueuedConverted
    }

    Write-Host "Found $($runsConverted.Count) runs to cancel."
    if ($runsConverted.Count -eq 0) {
        Write-Host 'No runs to cancel. Exiting.'
    } else {
        Write-Host 'Cancelling runs...'
        foreach ($run in $runsConverted) {
            gh run cancel $run.databaseId -R $repo
        }
    }
}

#f45873b3-b655-43a6-b217-97c00aa0db58 PowerToys CommandNotFound module

Import-Module -Name Microsoft.WinGet.CommandNotFound
#f45873b3-b655-43a6-b217-97c00aa0db58

$migprScriptUri = 'https://gist.githubusercontent.com/jtracey93/91f6c5da4646f06a04e3a005e06e11a5/raw/0d1d32ea7d9cf3d83373e446b0e84b1e776226ec/migpr.ps1'
$migprLocalPath = Join-Path -Path $env:TEMP -ChildPath 'migpr.ps1'

try {
    # Always pull the latest gist to keep the migration helpers current
    $response = Invoke-WebRequest -Uri $migprScriptUri -ErrorAction Stop
    $response.Content | Set-Content -Path $migprLocalPath -Encoding ascii
    . $migprLocalPath
    New-Alias -Name migpr -Value Invoke-MigPullRequest -Scope Global -Option AllScope
} catch {
    Write-Warning "Failed to download or load migpr helpers: $_"
}

gpg --version
