param(
    $body
)
Send-MailMessage -Body $body -From "servicemanager@jkwcireson.com" -SmtpServer "jkwciresondc" -Subject "Platform Action Test" -To "justinkworkman@jkwcireson.com"

return $body
