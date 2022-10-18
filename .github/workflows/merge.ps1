write-output "Testing merge script"

# $psaScriptClass = get-scsmclass -name Cireson.Powershell.Activity.Script$ -computerName $env:ServerName
# foreach ($file in ($env:filesOutput | convertfrom-json)) {
#     $fileName = $file.split('/')
#     if ($filename[0] -ne '.github') {
#         $shortName = $fileName[$fileName.length - 1]
#         $fnParts = $shortName.split('.')
#         if ($fnParts[$fnParts.length - 1] -eq '.ps1') {
#             $existing = get-scsmobject -class $psaScriptClass -computerName $env:ServerName
#             if ($existing) {
#                 $scriptBody = 
#                 set-scsmobject -property PowerShellScript
#             }
#         }
#     }
# }
$pwd