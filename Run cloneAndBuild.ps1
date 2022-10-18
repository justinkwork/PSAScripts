param(
	$parentId
)

import-module smlets

$parentRR = get-scsmobject -id $parentId
write-output "Got Parent Item: $($parentRR.DisplayName)"
$nowNumber = get-date $parentRR.actualStartDate -Format ssffff
write-output $nowNumber
$output = invoke-command -computername scsm2 -scriptblock {param($branch, $timeStamp, $repo); $errorActionPreference = "SilentlyContinue"; powershell c:\devopsbuild\cloneAndBuild.ps1 -branchName $branch -timeStamp $timeStamp -repoName $repo} -ArgumentList $parentRR.GitBranchName,$nowNumber,$parentRR.RepoName

write-output $output
$gitBranch = $parentRR.GitBranchName.replace("refs/heads/", "")
$fullFileName = "\\scsm2\c`$\devopsBuild\" + $parentRR.RepoName + "." + (get-date -Format yyyy.M.d).ToString() + $gitBranch.Replace("-", "").replace("dev/", "-") + $nowNumber + ".nupkg"

set-scsmobject -smobject $parentRR -property PostImplementationReview -value $fullFileName
