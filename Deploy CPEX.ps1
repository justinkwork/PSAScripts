param(
   $parentId
)

import-module smlets

$sa = get-scsmobject -id $parentId
write-output "Got Parent: $($sa.DisplayName)"
$paRel = get-scsmrelationshipobject -bytarget $sa | ?{$_.relationshipid -eq "2da498be-0485-b2b2-d520-6ebd1698e61b"}
$pa = get-scsmobject -id $paRel.SourceObject.Id
write-output "Got Next Parent: $($pa.DisplayName)"
$rrRel = get-scsmrelationshipobject -bytarget $pa | ?{$_.relationshipid -eq "2da498be-0485-b2b2-d520-6ebd1698e61b"}
$parentRR = get-scsmobject -id $rrRel.SourceObject.Id
write-output "Got Next Parent: $($parentRR.DisplayName)"

$server = $sa.Notes

write-output "Begin Deploy to $server"
write-output "`tChecking Path: $($parentRR.PostImplementationReview)"
if (test-path $parentRR.PostImplementationReview) {
       $pathSplit = $parentRR.PostImplementationReview.split("\")
       $fileName = $pathSplit[$pathSplit.length - 1]
       $targetPath = "\\$server\c`$\ProgramData\Cireson.Platform.Host\InstallableCpex\$fileName"
       Write-Output "`tTarget path: $targetPath"
	copy-item $parentRR.PostImplementationReview $targetPath
	start-sleep -seconds 5
	if (test-path $targetPath) {
	   write-output "`tCPEX Deployed Succesfully.  Restarting Platform..."
	   get-service -computername $server -name platform_cache | stop-service
	   get-service -computername $server -name platform_cache | start-service
	}
	else {
	   write-error "CPEX did NOT deploy!"
	}
} 
else {
   write-error "Could not find package!"
}
