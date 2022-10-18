param(
    $parentId
)

# Repo Information
$organization= "CiresonAvengers"
$projectName = "Support%20Customizations"
$filePath= "c:\DevOpsBuild\"
$token = ""

$GitAccessToken = $token

Import-Module smlets
$parentRR = Get-SCSMObject -id $parentId

$requestId = $parentRR.ActualWork
write-output "Pull Request ID: $($requestId.ToString())"

$AzureDevOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($token)")) }

$url =  "https://gitaccesstoken:$($GitAccessToken)@dev.azure.com/$organization/$projectName/_apis/git/pullrequests/$($requestId.ToString())?api-version=6.0"

$pull = Invoke-RestMethod -Method get -Uri $url -Headers $AzureDevOpsAuthenicationHeader

$updateUrl = "https://dev.azure.com/$organization/$projectName/_apis/git/repositories/$($pull.repository.id)/pullrequests/$($requestId.ToString())?api-version=6.0"

$updatedPull = @{
    status = "completed"
    completionOptions = @{
        deleteSourceBranch = $true
        transitionWorkItems = $true
        mergeCommitMessage = "Merged PR $($requestId.ToString()): $($pull.title)"
        mergeStrategy = "squash"
    }
    lastMergeSourceCommit = $pull.lastMergeSourceCommit
}

$updateResponse = Invoke-RestMethod -Method Patch -Uri $updateUrl -Headers $AzureDevOpsAuthenicationHeader -Body ($updatedPull | ConvertTo-Json) -ContentType "application/json"

Write-Output $updateResponse
