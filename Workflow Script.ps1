param(
	$WorkItemId
)

import-module smlets
$thisWorkItem = get-scsmobject -id $workItemId

Send-MailMessage -SmtpServer jkwciresondc -To justinkworkman@jkwcireson.com -From servicemanager@jkwcireson.com -Body $thisWorkItem.Description -Subject "[$($thisWorkItem.Name)] - $($thisWorkItem.Title)"
