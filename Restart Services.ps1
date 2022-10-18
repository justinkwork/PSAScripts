param(
$parentId
)
import-module smlets
$thisSR = get-scsmobject -id $parentId
$inputJSON = $thisSR.InputJSON | convertfrom-json 
set-scsmobject -smobject $thisSR -property 'Title' -value ($thisSR.Title + ' ' + $thisSR.CreatedOnServer)


if ($thisSR.CreatedOnServer -eq 'dev') {
    $server = 'jkwdev'
}
else {
    $server = 'jkwciresonscsm.jkwcireson.com'
}

if ($inputJSON.cachebuilder -eq 'true') {
	get-service -name 'cachebuilder' -computername $server | restart-service
}

if ($inputJSON.scsm -eq 'true') {
	$scriptBlock = {
        $services = @("omsdk", "omcfg", "healthservice")
        start-sleep -seconds 90
        foreach ($serv in $services) {
            get-service -name $serv | restart-service
        }
    }
    start-job -scriptblock $scriptBlock
	write-output "Sent Restart Job of SCSM Services to Background Job"
}

if ($inputJSON.platform -eq 'true') {
    get-service -name 'platform_cache' -computername $server | stop-service
    start-sleep -seconds 1
	get-service -name 'platform_cache' -computername $server | start-service
}

if ($inputJSON.iis -eq 'true') {
    if ($thisSR.CreatedOnServer -eq 'dev') {
        invoke-command -ComputerName $server -ScriptBlock {restart-webapppool -name 'CiresonPortal'}
    }
    else {
        restart-webapppool -name 'CiresonPortal'
    }
}