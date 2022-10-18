param(
    $srId
)
Import-Module Smlets
$webhookURL = "https://jkwcireson.webhook.office.com/webhookb2/8d0881af-7dad-4405-80e5-4505cee10216@5fa9364d-a051-4756-8589-8de9e3376718/IncomingWebhook/2b7229577afe4f6793b9fda1c1aa79e7/c0c950fb-f3bd-49a9-9f7d-1ea191b22533"

$thisSR = get-scsmobject -id $srId
$inputJSON = $thisSR.inputJson | ConvertFrom-Json

$json = @"
 {
    "type":"message",
    "attachments":[
       {
          "contentType":"application/vnd.microsoft.card.adaptive",
          "contentUrl":null,
          "content":{
             "$schema":"http://adaptivecards.io/schemas/adaptive-card.json",
             "type":"AdaptiveCard",
             "version":"1.2",
             "body":[
                 {
                    "type": "TextBlock",
                    "text": "Welcome $($inputJSON.FirstName) $($inputJSON.LastName)!!",
                    "weight": "bolder",
                    "size": "medium"
                },
                 {
            "type": "TextBlock",
            "text": "Everyone give a warm welcome to our latest $($inputJSON.Title) in $($inputJSON.City)!",
            "wrap": true
        }
             ]
          }
       }
    ]
 }
        
"@

Invoke-RestMethod -Uri $webhookURL -Method Post -Body $json -ContentType "application/json"
