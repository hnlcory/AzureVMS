# Set up email parameters
$recipients = Get-Content "C:\path\to\recipients.txt"
$subject = "Email Subject"
$body = "Dear {0},`n`nEmail Body"
$attachment = "C:\path\to\attachment.pdf"
$emailFrom = "your-email@domain.com"
$emailSmtpServer = "smtp.office365.com"
$emailPort = "587"
$emailCredential = Get-Credential

# Set up Outlook application and create new email message
$ol = New-Object -comObject Outlook.Application
$mail = $ol.CreateItem(0)

# Add recipients and personalize email intro
foreach ($recipient in $recipients) {
    $name = $recipient.Split("@")[0]
    $mail.Recipients.Add($recipient)
    $mail.Body = $body -f $name
}

# Set email properties
$mail.Subject = $subject
$mail.Attachments.Add($attachment)

# Set email sender and SMTP server
$mail.SendUsingAccount = $ol.Session.Accounts | Where-Object { $_.SmtpAddress -eq $emailFrom }
$mail.SendUsingAccount | Select-Object DisplayName
$mail.SendUsingAccount | Select-Object SmtpAddress
$mail.SendUsingAccount | Select-Object UserName
$mail.SendUsingAccount | Select-Object Password
$mail.SentOnBehalfOfName = $emailFrom
$mail.To = $recipients -join ","
$mail.From = $emailFrom

# Set SMTP server settings
$smtp = $ol.Session.SMTPServers.Item($emailSmtpServer)
$smtp.UseTLS = $true
$smtp.Port = $emailPort
$smtp.AuthenticationMethod = 3
$smtp.Credential = $emailCredential.GetNetworkCredential()

# Send email and display confirmation message
$mail.Send()
Write-Host "Email sent successfully to $($recipients -join ',')"
