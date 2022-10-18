param(
   $srId
)

function Add-LogMessage {
    param($Message, $Severity, $Path)
    if (!$Severity) {
        $Severity = 3
    }
    if (!$path) {
        $Path = $env:temp
    }
   
    $severities = @(
        [pscustomobject]@{
            Ordinal = 1
            Type = "ERROR"
        },
        [pscustomobject]@{
            Ordinal = 2
            Type = "WARN"
        },
        [pscustomobject]@{
            Ordinal = 3
            Type = "INFO"
        }
    )
    $outMessage = "$((get-date -Format "y-MM-d HH:mm:ss")) - $($severities | ?{$_.Ordinal -eq $Severity} | select -ExpandProperty Type) - $Message"
    $outMessage | Out-File $path -Encoding utf8 -Append

}

$srObject = get-scsmobject -id $srId
add-logmessage -Message "Got SRID: $srId" -Path "c:\Logs\UserOnboarding.txt"
if ($srObject) {
	add-logmessage -Message "`t Got SR: $srObject.Name" -Path "c:\Logs\UserOnboarding.txt"
	$input = $srObject.InputJson | convertfrom-json
	
	 $firstName = $input.FirstName
	 $lastName = $input.LastName
	 $city = $input.City
	 $state = $input.State
	 $address = $input.address
	 $department = $input.department
	 $title = $input.Title
	$manager = $input.Manager
	
	function New-RandomPass {
	    $pass = ""
	    $sets = @(
	        @{set = "@(33,35,36,37,38) | get-random"}
	        @{set = "Get-Random -Minimum 65 -Maximum 91"}
	        @{set = "Get-Random -Minimum 97 -Maximum 123"}
	        @{set = "Get-Random -Minimum 49 -Maximum 58"}
	    )
	
	    for ($x = 0; $x -lt (get-random -Minimum 12 -Maximum 20); $x++) {
	        $cValue = get-random -Minimum 0 -Maximum 4
	        $set = iex $sets[$cValue].Values
	        $pass += [char]$set 
	    }
	    0..3 |%{
	        $set = iex $sets[$_].Values
	        $pass += [char]$set 
	    }
	    return $pass
	}

	function Add-NewUser {
	    param(
	        $fName, $lName, $password, $city, $state, $address, $dept, $manager
	    ) 
	    $userName = "$($fName.toLower()).$($lName.toLower())"
	    $displayName = "$lName, $fName"
	    $upn = "$username@jkwcireson.com"
	
	    $cities = [pscustomobject]@{
	        KansasCity = "OU=KansasCity,OU=NorthAmerica,OU=JKWUsers,DC=jkwcireson,DC=com"
	        SanDiego = "OU=SanDiego,OU=NorthAmerica,OU=JKWUsers,DC=jkwcireson,DC=com"
	        Toronto = "OU=Toronto,OU=NorthAmerica,OU=JKWUsers,DC=jkwcireson,DC=com"
	        Westville = "OU=Westville,OU=NorthAmerica,OU=JKWUsers,DC=jkwcireson,DC=com"
	        Edinburgh = "OU=Edinburgh,OU=UK,OU=JKWUsers,DC=jkwcireson,DC=com"
	        London = "OU=London,OU=UK,OU=JKWUsers,DC=jkwcireson,DC=com"
	        Cairo = "OU=Cairo,OU=Africa,OU=JKWUsers,DC=jkwcireson,DC=com"
	    }
	
	    $targetOU = $cities."$($city.replace(' ', ''))"
	    $managerUser = Get-ADUser $manager
	    New-ADUser -SamAccountName $userName -DisplayName $displayName -GivenName $fName -Surname $lName -AccountPassword ($password | ConvertTo-SecureString -AsPlainText -force) `
	    -City $city -StreetAddress $address -Department $dept -Path $targetOU -UserPrincipalName $upn -EmailAddress $upn -Name "$fName $lName" -Enabled $true -Title $title -Description "$title - $dept" `
	    -Manager $managerUser
	
	}
	
	$password = New-RandomPass
	#maybe send an email to the manager with the new password?
	
	$input | add-member -membertype NoteProperty -Name Username -value  "$($firstName.toLower()).$($lastName.toLower())"
	$srobject | set-scsmobject -property InputJson -value ($input | convertto-json -compress)
	add-logmessage -Message "`tAttempting to add user: $($input.username)" -Path "c:\Logs\UserOnboarding.txt"
	try {
	    Add-NewUser -fName $firstName -lName $lastName -password $password -city $city -state $state -address $address -dept $department -manager $manager
	    $jacreds = get-content "c:\users\justin.admin\documents\ac.txt" -raw | convertfrom-json
	    $pass = [system.text.encoding]::UTF8.GetString([system.convert]::frombase64string($jacreds.password))
	    $creds = [pscredential]::new($jacreds.username, ($pass | convertto-securestring -force -asplaintext))
	    $cmd = "Start-ADSyncSyncCycle -PolicyType Delta"
	    $syncCommand = [scriptblock]::create($cmd)
	    try {
	      invoke-command -computername jkwciresondc.jkwcireson.com -command $syncCommand -credential $creds
	    }
	    catch {
	     add-logmessage -Message "Account could not be added: $($_.exception)" -Path "c:\Logs\UserOnboarding.txt" -severity 1
	    }
	    
	}
	catch {
	    add-logmessage -Message "Account could not be added: $($_.exception)" -Path "c:\Logs\UserOnboarding.txt" -severity 1
	    
	}

}
else {
 	add-logmessage -Message "Could not get the Parent!" -Path "c:\Logs\UserOnboarding.txt" -severity 1
 	throw "Could not get the Parent!"
 	
}
