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

$affectedUserRel = get-scsmrelationshipobject -bysource $thisSR | ?{$_.RelationshipId -eq 'dff9be66-38b0-b6d6-6144-a412a3ebd4ce'}
$user = get-scsmobject -Id $affectedUserRel.targetobject.Id

$tikitUser = Get-TikitUser -username $user.UserName -tikitToken $token

$newInputJson = @{TikitUser = $tikitUser.Id} | ConvertTo-Json

$thisSr | Set-SCSMObject -Property InputJson -value $newInputJson