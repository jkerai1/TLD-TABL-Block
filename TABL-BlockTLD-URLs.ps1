#Install-Module ExchangeOnlineManagement
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline -ShowBanner:$false

# Fetch raw TLD list
$BlockList = Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/jkerai1/TLD-TABL-Block/refs/heads/main/LargerCombinedBadTLDs.txt' -UseBasicParsing | Select-Object -ExpandProperty Content

# Review the list of URLs above (manually or KQL), then come back here to add/remove exclusions as necessary. NO RESPONSIBILITY IS TAKEN IF YOU CAUSE BUSINESS IMPACT.
$exclusion = @('info', 'example', 'biz', 'link', 'help', 'live', 'support')

foreach ($line in $BlockList.Split([Environment]::NewLine)) {
    $trimmedLine = $line.Trim()

    # Skip empty lines, comments, and excluded TLDs
    if (-not [string]::IsNullOrWhiteSpace($trimmedLine) -and -not $trimmedLine.StartsWith("#") -and $exclusion -notcontains $trimmedLine) {
        # Basic TLD validation 
        if ($trimmedLine -match '^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$') {
            # Format for TABL URL blocking: *.<tld>/*
            $urlPattern = "*.$trimmedLine/*".ToLowerInvariant()
            Write-Host "Blocking URL pattern: $urlPattern"
            New-TenantAllowBlockListItems -ListType Url -Block -Entries $urlPattern -NoExpiration -Notes "Blocked TLD per https://github.com/jkerai1/TLD-TABL-Block/tree/main"
        } else {
            Write-Warning "Skipping invalid TLD: '$trimmedLine'"
        }
    }
}
