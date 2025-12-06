#Install-Module ExchangeOnlineManagement
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline

# Fetch raw TLD list (fixed URL, no trailing spaces)
$BlockList = Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/jkerai1/TLD-TABL-Block/refs/heads/main/LargerCombinedBadTLDs.txt' -UseBasicParsing | Select-Object -ExpandProperty Content

$exclusion = @('info', 'example')

foreach ($line in $BlockList.Split([Environment]::NewLine)) {
    $trimmedLine = $line.Trim()

    # Skip empty lines, comments, and excluded TLDs
    if (-not [string]::IsNullOrWhiteSpace($trimmedLine) -and
        -not $trimmedLine.StartsWith("#") -and
        $exclusion -notcontains $trimmedLine) {

        # Basic TLD validation (optional but recommended)
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
