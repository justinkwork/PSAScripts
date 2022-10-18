$ip = Invoke-RestMethod -Method get -Uri 'https://api.ipify.org?format=json'

$html = "<h2>Your IP Address is: <a href='http://$($ip.ip)'>$($ip.ip)<a><h2>"

Send-MailMessage -To justinkwork@gmail.com -SmtpServer smtp.jkwcireson.com -BodyAsHtml -From servicemanager@jkwcireson.com -Body $html -Subject IP
