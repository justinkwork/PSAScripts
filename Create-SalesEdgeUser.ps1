param($srId)
Import-Module SMlets
$moduleBody = get-content "C:\Program Files\Common Files\SalesEdge\SalesEdge.ps1" -Raw
invoke-expression -command $modulebody

$onboardSR = Get-SCSMObject -Id $srId
$token = '29e87677bb864a6ebc69b1fa892f0c81-9e362ddaa9d84fc286fb1ad8f721077f'
$server = "salesedge.jkwcireson.com"

if ($onboardSR) {
	$input = $onboardSR.InputJSON | convertfrom-json
	$name = "$($input.FirstName) $($input.LastName)"
	try {
		$connection = New-SalesEdgeConnection -Token $token -Server $server -SSL
		New-SalesEdgeUser -Connection $connection -Name $name -City $input.city -Address $input.Address -Phone $input.Phone
	}
	catch {
		write-output "Could not create SalesEdge user! $($_.exception.message)"
	}
}
else {
	write-output "Could not get Parent SR!"
}


    
