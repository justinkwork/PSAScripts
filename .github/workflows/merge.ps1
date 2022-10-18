write-output "Testing merge script"

$psaScriptClass = get-scsmclass -name Cireson.Powershell.Activity.Script$ -computerName $env:ServerName
foreach ($file in ($env:filesOutput | convertfrom-json)) {
    $fileName = $file.split('/')
    if ($filename[0] -ne '.github') {
        $shortName = $fileName[$fileName.length - 1]
        write-output "ShortName = $shortName `n"
        $fnParts = $shortName.split('.')
        if ($fnParts[$fnParts.length - 1] -eq 'ps1') {
            $existing = get-scsmobject -class $psaScriptClass -computerName $env:ServerName -filter "Title -eq $($fnParts[0])"
            if (!$existing) {
                try {
                    write-output "Attempting to create new Script on $($env:servername) called $shortName"
                    new-scsmobject -computerName $env:ServerName -class $psaScriptClass -propertyHashTable @{
                        Id = [guid]::newguid()
                        Title = $fnParts[0]
                        Enabled = $true
                    }
                }
                catch {
                    throw "Could not create PSA Script"
                }
                $existing = get-scsmobject -class $psaScriptClass -computerName $env:ServerName -filter "Title -eq $($fnParts[0])"
            }

            $scriptBody = get-content $pwd/$shortname
            write-output "Setting Script on PSA Script Object"
            $existing | set-scsmobject -property PowerShellScript -value $scriptBody -computerName $env:ServerName
        }
    }
}
