param(
	$activityId, $parentId
)
import-module smlets
$activity = get-scsmobject -Id $activityId
$psaScriptClass = get-scsmclass -name Cireson.Powershell.Activity.Script 
$script = get-scsmobject -class $psaScriptClass -filter "DisplayName -eq $($activity.Description)"

if ($Script) {
	write-output "Got Script: $($script.DisplayName)`n"
	
	$s = [ScriptBlock]::Create($script.PowershellScript)

	Invoke-Command -ScriptBlock $s -ArgumentList $parentId
}
