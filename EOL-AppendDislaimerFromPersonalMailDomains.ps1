# This PowerShell Script requires ExchangeOnlineManagement Module.
# It will add a disclaimer to emails from personal email domains. The transport rule is created in a DISABLED state.

# URL containing the list of public email domains
$DomainListUrl = "https://raw.githubusercontent.com/cricci/public_email_domains/refs/heads/main/public_email_domains-WORKING"

# Download the domain list from the URL
$Domains = Invoke-WebRequest -Uri $DomainListUrl | Select-Object -ExpandProperty Content
$DomainArray = $Domains -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }

# Define the HTML disclaimer (minimized to fit character limit)
$HtmlDisclaimer = '<table width="100%" cellpadding="0" cellspacing="0" border="0"><tr><td style="background-color:#8b0000;border-left:4px solid #cc0000;padding:10px 12px"><table cellpadding="0" cellspacing="0"><tr><td style="padding-right:8px;color:#fff;font-size:16px">⚠</td><td style="color:#fff;font-family:Arial;font-size:13px"><b>Caution:</b> This email is not from a business. Do not share data or log into platforms from links inside this message.</td></tr></table></td></tr></table>'

# Create the transport rule with HTML disclaimer (disabled by default)
New-TransportRule -Name "Add Disclaimer to Public Email Domains" `
    -Enabled $false `
    -SenderDomainIs $DomainArray `
    -ApplyHtmlDisclaimerLocation Prepend `
    -ApplyHtmlDisclaimerText $HtmlDisclaimer `
    -ApplyHtmlDisclaimerFallbackAction Wrap
