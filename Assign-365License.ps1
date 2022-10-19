param($srId)
$variables = Get-Content "c:\PSAVariables.txt" | ConvertFrom-Json 
$clientId = $variables.Assign365License.clientId
$tenantId = $variables.Assign365License.tenatId
$certThum = $variables.Assign365License.certThumb

$thisSR = Get-SCSMObject -Id $srId
$input = $thisSR.InputJSON | ConvertFrom-Json

$userName = "$($input.firstName.toLower()).$($input.lastName.toLower())"

$userUPN = "$username@$($variables.domain)"

$cities = [pscustomobject]@{
    KansasCity = "US"
    SanDiego = "US"
    Toronto = "CA"
    Westville = "US"
    Edinburgh = "GB"
    London = "GB"
    Cairo = "EG"
}

$userLoc = $cities."$($input.city.replace(' ', ''))"

Connect-MgGraph -ClientId $clientId -TenantId $tenantId -CertificateThumbprint $certThum
$myE5Sku = $variables.Assign365License.myE5Sku

Update-MgUser -UserId $userUPN -UsageLocation $userLoc
Set-MgUserLicense -UserId $userUPN -AddLicenses @{SkuId = $myE5Sku} -RemoveLicenses @()
