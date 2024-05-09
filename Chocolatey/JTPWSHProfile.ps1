function ghcs {
	# Debug support provided by common PowerShell function parameters, which is natively aliased as -d or -db
	# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_commonparameters?view=powershell-7.4#-debug
	param(
		[ValidateSet('gh', 'git', 'shell')]
		[Alias('t')]
		[String]$Target = 'shell',

		[Parameter(Position=0, ValueFromRemainingArguments)]
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
				CommandLine = $executeCommand
				ExecutionStatus = [Management.Automation.Runspaces.PipelineState]::NotStarted
				StartExecutionTime = $now
				EndExecutionTime = $now.AddSeconds(1)
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
		[Parameter(Position=0, ValueFromRemainingArguments)]
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
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\jtracey93new.omp.json" | Invoke-Expression

Import-Module PSReadLine

New-Alias wipealz D:\GitRepos\GitHub-jtracey93\PublicScripts\Azure\PowerShell\Enterprise-scale\Wipe-ESLZAzTenant.ps1 -Scope Global -Option AllScope
New-Alias tf terraform.exe -Scope Global -Option AllScope

function gitLogOneline {
  git.exe log --oneline
}
New-Alias -Name glo -Value gitLogOneline -Scope Global -Option AllScope

