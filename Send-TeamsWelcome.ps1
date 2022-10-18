param(
    $srId
)
Import-Module Smlets
$webhookURL = ""

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
