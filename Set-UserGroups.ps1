param(
   $srId
)

$srObject = get-scsmobject -id $srId
if ($srObject) {
	$input = $srObject.InputJson | convertfrom-json
	
	 $firstName = $input.FirstName
	 $lastName = $input.LastName
	 $city = $input.City
	 $state = $input.State
	 $address = $input.address
	 $department = $input.department
	 $title = $input.Title
	 $manager = $input.Manager
	 
	 $username = $input.UserName
	 $aduser = get-aduser $username
	 if ($aduser) {
		$cityOU = Get-ADOrganizationalUnit -Filter "Name -eq '$city'" 
		$regionOU = Get-ADOrganizationalUnit $city0U.distinguishedName.Replace("OU=$city,", "") 
		$groups = @(
		    $department, 
		    "grp-dl-$city", 
		    $region0U.Name
	       )
		foreach ($g in $groups) { 
			Add-ADGroupMember -Identity $g -Members $userName 
		}
	}
	else {
		write-output "Could not get AD User"
	}
}
else {
	write-output "Could not get parent"
}
