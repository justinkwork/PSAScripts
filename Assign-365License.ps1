param($srId)
$clientId = "5fede202-56a2-45a9-a050-082833800b69"
$tenantId = "5fa9364d-a051-4756-8589-8de9e3376718"
$certThum = "26D195D75EFD4E4682C933580B5240387DFD6B66"

$thisSR = Get-SCSMObject -Id $srId
$input = $thisSR.InputJSON | ConvertFrom-Json

$userName = "$($input.firstName.toLower()).$($input.lastName.toLower())"

$userUPN = "$username@jkwcireson.com"

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
$myE5Sku = "c42b9cae-ea4f-4ab7-9717-81576235ccac"

Update-MgUser -UserId $userUPN -UsageLocation $userLoc
Set-MgUserLicense -UserId $userUPN -AddLicenses @{SkuId = $myE5Sku} -RemoveLicenses @()
