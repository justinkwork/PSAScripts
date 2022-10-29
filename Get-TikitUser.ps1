param($srId)
Import-Module SMLets

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
    $outMessage | Out-File $path -Encoding ascii -Append

}
function Get-TikitUser {
    param(
        $username, $tikitToken
    )
    $header = @{
        Authorization = "Bearer $tikitToken"
    }

    $user = Invoke-RestMethod -Method Get -Uri "https://app.tikit.ai/api/CdmUser?`$filter=UserPrincipalName eq '$username@jkwcireson.com'" -Headers $header
    return $user.value[0]
}

$logPath = "c:\Logs\get-tikituser.log"

Add-LogMessage -Message $srId -path $logpath

$psaVariables = Get-Content "c:\PSAVariables.txt" | ConvertFrom-Json

$token = $psaVariables."Get-TikitUser".tikitToken
$thisSR = get-scsmobject -Id $srId

$SrRels = get-scsmrelationshipobject -bysource $thisSR 
$affecterUserRel = $srRels | ?{$_.RelationshipId -eq 'dff9be66-38b0-b6d6-6144-a412a3ebd4ce'}
$user = get-scsmobject -Id $affecterUserRel.targetobject.Id
$tikitUser = Get-TikitUser -username $user.UserName -tikitToken $token
Add-LogMessage -Message "Affected User: $($user.DisplayName)" -path $logpath
$activityRels = $SrRels | ?{$_.RelationshipId -eq "2da498be-0485-b2b2-d520-6ebd1698e61b"}
$activities = @()
foreach ($a in $activityRels) {
    $emoAct = get-scsmobject -id $a.TargetObject.Id
    $activities += $emoAct
}
$thisActivity = $activities|?{$_.description -eq 'Get-TikitUser'}
Add-LogMessage -Message "This Activity: $($thisActivity.Name)" -path $logpath
$nextActivity = $activities | ?{$_.sequenceId -eq $($thisActivity.SequenceId + 1)}

if ($nextActivity) {
    Add-LogMessage -Message "Next Activity: $($nextActivity.Name)" -path $logpath
    $nextActivity | set-scsmobject -property JKWInt1 -value $tikitUser.Id
    $bodyContent = @(
        @{ClassPropertyName = "Text01";PropertyType = "Body"; PropertyName = "Title"; PropertyValue = "Text2"}
        @{ClassPropertyName = "Text01";PropertyType = "Body"; PropertyName = "PriorityId"; PropertyValue = "JKWInt3"}
        @{ClassPropertyName = "Text01";PropertyType = "Body"; PropertyName = "TicketTypeId"; PropertyValue = "JKWInt4"}
        @{ClassPropertyName = "Text01";PropertyType = "Body"; PropertyName = "StatusId"; PropertyValue = "JKWInt5"}
        @{ClassPropertyName = "Text01";PropertyType = "Body"; PropertyName = "RequesterId"; PropertyValue = "JKWInt1"}
    )
    $nextActivity | set-scsmobject -property "WebhookUseCustomBodyContent" -value ($bodyContent | convertto-json -compress)
}
else {
    write-output "Could not get next activity!"
    Add-LogMessage -Message "Could not get next activity!" -path $logpath
}