param($parentId, $targetPath)

import-module smlets

$containsActivityRelationshipId = "2da498be-0485-b2b2-d520-6ebd1698e61b"
$sequential = get-scsmobject -id $parentId
$pa = get-scsmrelationshipobject -bytarget $sequential | ?{$_.relationshipid -eq $containsActivityRelationshipId}

$sr = get-scsmrelationshipobject -bytarget (get-scsmobject -id $pa.sourceobject.id) | ?{$_.relationshipid -eq $containsActivityRelationshipId}

$srObject = get-scsmobject -id $sr.sourceObject.id

if (test-path "$targetPath\build") {
       write-output "Target Path exists....renaming!"
       if (test-path "$targetPath\build.old") {
       	remove-item "$targetPath\build.old" -recurse -force
       }
	rename-item "$targetPath\build" "$targetPath\build.old"
}
write-output "Unzipping Files from $($srobject.inputjson) to $targetPath"
expand-archive -literalpath $srObject.inputjson -DestinationPath $targetPath
move-item "$targetPath\drop\build" "$targetPath\build"
remove-item "$targetPath\drop"

