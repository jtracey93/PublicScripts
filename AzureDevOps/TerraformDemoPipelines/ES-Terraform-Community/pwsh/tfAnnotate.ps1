Param ( 
    [Parameter(Mandatory = $true)][String]$JsonPlanPath
)

$json = Get-Content $JsonPlanPath | ConvertFrom-Json
$changes = $json.resource_changes `
| Where-Object { ($_.change.actions[0] -ne 'no-op') -and ($_.change.actions[0] -ne 'read') }

function ToIcon($action) {
    switch ($action) {
        "create" { ":sparkles:" }
        "update" { ":pencil2:" }
        "delete" { ":bomb:" }
        Default { return $action }
    }
}

if (-not $changes) {
    $comment = @{ content = "**Terraform Plan changes summary :**`r`nNo Changes ! :thumbsup:`r`n`r`nThis comment thread is closed as there are no changes !"; commentType = "text" }
    $request.status = "closed"
}else {
    $comment = @{ content = "**Terraform Plan changes summary :**`r`n"; commentType = "codeChange" }
    foreach ($change in $changes) {
        $actions = $change.change.actions | ForEach-Object { ToIcon($_) }
        $nameBefore = $change.change.before.name
        $nameAfter = $change.change.after.name

        if($nameBefore -and $nameAfter -and ($nameBefore -ne $nameAfter)) {
            $resource = "$nameBefore :arrow_right: $nameAfter"
        } elseif ($nameBefore -and $nameAfter) {
            $resource = $nameBefore
        } elseif ($nameBefore -and (-not $nameAfter)) {
            $resource = $nameBefore
        } elseif ($nameAfter -and (-not $nameBefore)) {
            $resource = $nameAfter
        }

        $comment.content += "$([System.String]::Join(" ", $actions)) $resource ($($change.type))`r`n"
    }   
}

$linkUrl = [System.Uri]::EscapeUriString("${env:System_TeamFoundationCollectionUri}${env:System_TeamProject}/_build/results?buildId=${env:BUILD_BUILDID}&view=logs&j=${env:SYSTEM_JOBID}")
$comment.content += "`r`nSee [Pipeline ${env:BUILD_BUILDNUMBER} logs]($linkUrl)"

$request.comments.Add($comment) | Out-Null
$url = "${env:System_TeamFoundationCollectionUri}${env:System_TeamProject}/_apis/git/repositories/${env:Build_Repository_ID}/pullRequests/${env:system_pullRequest_pullRequestId}/threads?api-version=5.1"
Invoke-RestMethod -Method "POST" -Uri $url -Body ($request | ConvertTo-Json) -ContentType "application/json" -Headers @{ Authorization = "Bearer ${env:SYSTEM_ACCESSTOKEN}" }
