param(
    [parameter(mandatory=$true)][string]$WorkItemID
    )

Import-Module smlets

$thisWorkItem = Get-SCSMObject -id $WorkItemID
$workItemJson = $thisWorkItem.InputJSON |ConvertFrom-Json
$articleId = $workItemJson.ArticleId
$affectedUser = get-scsmobject -id (get-scsmrelationshipobject -bysource $thisWorkItem -filter {Relationshipid -eq 'dff9be66-38b0-b6d6-6144-a412a3ebd4ce'}).targetobject.id

function newForm {
param(
    $createdByUserId
)
$form = @{
formJson = @{
    isDirty = $true
    current = @{
        IsNew = $true
        ArticleId = 0
        Title = "Title missing"
        Abstract = $null
        Keywords = $null
        EndUserContent = $null
        EndUserContentType = $null
        AnalystContent = $null
        AnalystContentType = $null
        ExternalURLSource = $null
        ExternalURL = $null
        LocaleID = 0
        LanguageLocaleID = @{
          Id = "10CE36CE-AA59-4F36-9CE9-2AB6DF031A51"
          Name = "English"
          HierarchyLevel = 0
          HierarchyPath = $null
        }
        VendorArticleID = $null
        Popularity = 100
        KAOwner = $null
        Type = $null
        KAType = @{
          Id = $null
          Name = ""
          HierarchyLevel = 0
          HierarchyPath = $null
        }
        Category = $null
        KACategory = @{
          Id = $null
          Name = ""
          HierarchyLevel = 0
          HierarchyPath = $null
        }
        CreatedBy = $createdByUserId
        CreatedDate = "0001-01-01T00:00:00.000Z"
        LastModifiedBy = $createdByUserId
        LastModifiedDate = "0001-01-01T00:00:00.000Z"
        NameRelationship = @(
          @{
            Name = "RelatesToIncident"
            Class = "943d298f-d79a-7a29-a335-8833e582d252"
            RelationshipId = "42179172-3d24-cfc8-3944-b0a18f550214"
          }
        )
        RelatesToIncident = @{
          DisplayName = $null
          BaseId = $null
          ObjectGuid = $null
        }
        Activity = $null
        Status = @{
          Id = "9508797e-0b7a-1d07-9fa3-587723f09908"
        }
        IsImported = $false
        RelatesToServiceOffering = @()
        RelatesToRequestOffering = @()
        Rating = 0
        ViewCount = 0
        Comments = @()
        CategoryBreadcrumbs = $null
        ExternalId = "00000000-0000-0000-0000-000000000000"
      }
    original = $null
    }
}
return $form
}
Function Get-CiresonAPIResults {
    param(
        [string]$siteServer,
        [string]$apiUser,
        [string]$apiPass,
        [string]$apiEndpoint,
        [string]$PostBody,
        [switch]$UseSSL,
        [switch]$alternateAPI
    )

    if ($UseSSL) {
        $site = "https://$siteServer"
    }
    else {
        $site = "http://$siteServer"
    }

    $credentials = @{
        UserName=$apiUser
        Password=$apiPass
        LanguageCode='ENU'
    }

    $jsonCredentials = $credentials | ConvertTo-Json
    $url = $site+"/api/V3/Authorization/GetToken"
    $apiKey = try { Invoke-RestMethod $url -Method POST -Body $jsonCredentials -ContentType 'application/json' } catch { $_.Exception.Response }
    $authVal = "Token " + $apiKey

    if ($alternateAPI) {
        $url = $site + $apiEndpoint
    }
    else {
        $url = $site + "/api/V3/$apiEndpoint"
    }
    if ($PostBody) {
        $response = try { Invoke-RestMethod $url -Method POST -Body $PostBody -ContentType 'application/json' -Headers @{"AUTHORIZATION"=$authVal} } catch { $_.Exception  }

    }
    else {
        $response = try { Invoke-RestMethod $url -Method GET -ContentType 'application/json' -Headers @{"AUTHORIZATION"=$authVal} } catch { $_.Exception.response  }
    }
    return $response 
}

$supportCreds = get-content "c:\portal\support.txt" | convertfrom-json
$localCreds = get-content "C:\portal\dev.txt" | convertfrom-json

$remoteArticle = Get-CiresonAPIResults -siteServer support.cireson.com -apiUser $supportCreds.username -apiPass $supportCreds.password -apiEndpoint /Article/Get?articleId=$articleId -UseSSL

$form = newForm -createdByUserId $affectedUser.Id
$form.formJson.current.title = $remoteArticle.Title
$form.formJson.current.Status.Id = $remoteArticle.Status.Id
$form.formjson.current.Endusercontent = $remoteArticle.EndUserContent
$form.formjson.current.Analystcontent = $remoteArticle.Analystcontent
$form.formJson.current.Keywords = $remoteArticle.Keywords

$jsonBody = $form| ConvertTo-Json -Depth 4
$server = $($thisWorkItem.CreatedOnServer)
$newArticle = Get-CiresonAPIResults -siteServer $server -apiUser $localCreds.username -apiPass $localCreds.password -apiEndpoint KnowledgeBase/AddorUpdateHTMLKnowledgeApi -PostBody $jsonBody 
Write-Output "New Article ID is $newArticle"

$mailbody = @"
<table>
    <tr><td><h2>Support Article ID: </h2></td><td><h2>$articleId</h2></td></tr>
    <tr><td><h2>Local Article ID: </h2></td><td><h2><a href='https://$($server + ".jkwcireson.com")/KnowledgeBase/Edit/$newArticle'>$newArticle</a></h2></td></tr>
</table>
"@



Send-MailMessage -Subject "Support KB Article Generated: $newArticle" -Body $mailbody -BodyAsHtml -To $($affectedUser.upn) -From "servicemanager@jkwcireson.com" -SmtpServer "jkwcireson.mail.protection.outlook.com"  
