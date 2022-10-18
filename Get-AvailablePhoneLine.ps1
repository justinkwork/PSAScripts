param($srId)
Import-Module SMlets
$thisSR = get-scsmobject -Id $srid

if ($thisSR) {
	$inputJson = $thisSR.InputJSON | ConvertFrom-Json
	$PhoneLineClass = Get-SCSMClass -name 'JKW.Telephony.PhoneLine'
	$extensionRel = Get-SCSMRelationshipClass -name 'JKW.PhoneLineHasExtension'
	$phoneLine = Get-SCSMObject -class $phoneLineClass -filter "Notes -like '*$($inputJson.city.replace(' ', ''))*'"
	$extensionRelInstances = Get-SCSMRelationshipIbject -bysource $phoneLIne -filter "Relationshipid -eq '$($extensionRel.Id.Guid)'"
	$extension = 0
	foreach ($ext in $extensionRelInstances) {
		$t = Get-SCSMObject -id $ext.TargetObject.Id
		if ([int]::parse($t.ExtensionNumber) -gt $extension) {
			$extension = [int]::parse($t.ExtensionNumber)
		}
	}
	$extension++
	$userPhone = $phoneLine.Number + " x" + $extension.toString()
	$inputJson | Add-Member -MemberType NoteProperty -Name "Phone" -Value $userPhone
	try {
		$thisSR | Set-SCSMObject -property InputJson -value ($inputJson | ConvertTo-Json -compress)
		Set-ADUser -identity $inputJson.username -OfficePhone $userPhone
	}
	catch {
		write-output "Could not set Phone Number for user! $($_.exception.Message)" 
	}
}
else {
	write-output "Could not get Parent SR!"
}

