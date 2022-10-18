param(
    $parentId
)

# Repo Information
$organization = "justinkworkman"
$projectName = "TFSFluent"
$token = "ogds6lnofxa674bgdkz6vca25zndqbua7oojtq4ngzyzbqm4df7a"

$GitAccessToken = $token

Import-Module smlets
$parentRR = Get-SCSMObject -id $parentId

$buildId = $parentRR.ActualWork

$AzureDevOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($token)")) }

$url = "https://gitaccesstoken:$($GitAccessToken)@dev.azure.com/$($organization)/$($projectName)/_apis/build/builds/$($buildId.ToString())/artifacts?artifactName=drop&api-version=4.1"

$pull = Invoke-RestMethod -Method get -Uri $url -Headers $AzureDevOpsAuthenicationHeader

Invoke-WebRequest -Uri $pull.resource.downloadUrl -Headers $AzureDevOpsAuthenicationHeader -OutFile \\scsm2\c$\DevOpsBuild\TfsFluent\drop.zip

$parentRR | set-scsmobject -property InputJson -value "\\scsm2\c$\DevOpsBuild\TFSFluent\drop.zip"


