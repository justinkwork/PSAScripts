param($srId)
Import-Module SMLets
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

$psaVariables = Get-Content "c:\PSAVariables.txt" | ConvertFrom-Json

$token = $psaVariables."Get-TikitUser".tikitToken
$thisSR = get-scsmobject -$srId

$SrRels = get-scsmrelationshipobject -bysource $thisSR 
$affecterUserRel = $srRels | ?{$_.RelationshipId -eq 'dff9be66-38b0-b6d6-6144-a412a3ebd4ce'}
$user = get-scsmobject -Id $affecterUserRel.targetobject.Id
$tikitUser = Get-TikitUser -username $user.UserName -tikitToken $token

$activityRels = $SrRels | ?{$_.RelationshipId -eq "2da498be-0485-b2b2-d520-6ebd1698e61b"}
$activities = @()
foreach ($a in $activityRels) {
    $emoAct = get-scsmobject -id $a.TargetObject.Id
    $activities += $emoAct
}
$thisActivity = $activities|?{$_.description -eq 'Get-TikitUser'}
$nextActivity = $activities | ?{$_.sequenceId -eq $($thisActivity.SequenceId + 1)}

if ($nextActivity) {
    $nextActivity.Text6 = $tikitUser.Id
}
else {
    write-output "Could not get next activity!"
}