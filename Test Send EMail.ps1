param(
	$body
)
Send-MailMessage -SmtpServer jkwciresondc -To justinkworkman@jkwcireson.com -From servicemanager@jkwcireson.com -Body $body -Subject "Testing from PS" 
