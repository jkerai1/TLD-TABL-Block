# This PowerShell Script requires ExchangeOnlineManagement Module.
# It will add a disclaimer to emails from personal email domains.
# Creates multiple transport rules to stay within the 8192 character limit.
# Automatically detects when the domain list is updated and refreshes the rules.

#If you need to install the module uncomment the line below
#Install-Module ExchangeOnlineManagement 

Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline -ShowBanner:$false

# URL containing the list of public email domains
$DomainListUrl = "https://raw.githubusercontent.com/cricci/public_email_domains/refs/heads/main/public_email_domains-WORKING"

# Download the domain list from the URL
Write-Host "Downloading domain list from GitHub... ($DomainListUrl)" -ForegroundColor Cyan
$Domains = Invoke-WebRequest -Uri $DomainListUrl | Select-Object -ExpandProperty Content
$DomainArray = $Domains -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" } | Sort-Object

Write-Host "✓ Downloaded $($DomainArray.Count) domains from GitHub" -ForegroundColor Green

# Get existing rules and extract all configured domains
Write-Host "`nChecking existing Exchange Online transport rules..." -ForegroundColor Cyan
$ExistingRules = Get-TransportRule | Where-Object { $_.Name -like "Add Disclaimer to Public Email Domains - Part*" }

$ExistingDomains = @()
if ($ExistingRules) {
    Write-Host "Found $($ExistingRules.Count) existing rule(s)" -ForegroundColor Gray
    
    foreach ($Rule in $ExistingRules) {
        $ExistingDomains += $Rule.SenderDomainIs
    }
    
    $ExistingDomains = $ExistingDomains | Sort-Object -Unique
    Write-Host "✓ Extracted $($ExistingDomains.Count) unique domains from existing rules" -ForegroundColor Green
}
else {
    Write-Host "No existing rules found. This appears to be the first run." -ForegroundColor Gray
}

# Compare the domain lists
$NeedsUpdate = $false
$CompareResult = Compare-Object -ReferenceObject $ExistingDomains -DifferenceObject $DomainArray

if ($CompareResult) {
    $NeedsUpdate = $true
    $AddedDomains = ($CompareResult | Where-Object { $_.SideIndicator -eq '=>' }).Count
    $RemovedDomains = ($CompareResult | Where-Object { $_.SideIndicator -eq '<=' }).Count
    
    Write-Host "`n⚠ Domain list has changed!" -ForegroundColor Yellow
    if ($AddedDomains -gt 0) {
        Write-Host "  + $AddedDomains new domain(s) to add" -ForegroundColor Green
    }
    if ($RemovedDomains -gt 0) {
        Write-Host "  - $RemovedDomains domain(s) to remove" -ForegroundColor Red
    }
    
    # Remove existing rules
    Write-Host "`nRemoving existing rules for update..." -ForegroundColor Yellow
    foreach ($Rule in $ExistingRules) {
        try {
            Remove-TransportRule -Identity $Rule.Identity -Confirm:$false
            Write-Host "  ✓ Removed: $($Rule.Name)" -ForegroundColor Green
        }
        catch {
            Write-Host "  ✗ Failed to remove: $($Rule.Name) - $_" -ForegroundColor Red
        }
    }
}
else {
    Write-Host "`n✓ Domain lists are identical. No update needed." -ForegroundColor Green
    Write-Host "Current configuration matches the GitHub source ($($DomainArray.Count) domains)" -ForegroundColor Gray
    exit 0
}

# Define the HTML disclaimer (minimized to fit character limit)
$HtmlDisclaimer = '<table width="100%" cellpadding="0" cellspacing="0" border="0"><tr><td style="background-color:#8b0000;border-left:4px solid #cc0000;padding:10px 12px"><table cellpadding="0" cellspacing="0"><tr><td style="padding-right:8px;color:#fff;font-size:16px">⚠</td><td style="color:#fff;font-family:Arial;font-size:13px"><b>Caution:</b> This email is not from a business. Do not share data or log into platforms from links inside this message.</td></tr></table></td></tr></table>'

# Based on testing: 3534 chars of domains = 9087 total (overhead ~5553)
# To stay under 8192: 8192 - 5553 = 2639 chars max for domains
$MaxCharsPerRule = 2500  # Conservative limit based on actual overhead
$CurrentChunk = @()
$CurrentLength = 0
$ChunkNumber = 1
$SuccessfulRules = 0

Write-Host "`nCreating new transport rules..." -ForegroundColor Cyan
Write-Host "Total domains to process: $($DomainArray.Count)" -ForegroundColor Cyan
Write-Host "Splitting into chunks (max ~2500 chars per rule to account for 5500+ char overhead)..." -ForegroundColor Cyan

foreach ($Domain in $DomainArray) {
    $DomainLength = $Domain.Length + 1  # +1 for comma/separator
    
    # Check if adding this domain would exceed the limit
    if (($CurrentLength + $DomainLength) -gt $MaxCharsPerRule -and $CurrentChunk.Count -gt 0) {
        # Create a transport rule for the current chunk
        $RuleName = "Add Disclaimer to Public Email Domains - Part $ChunkNumber"
        
        Write-Host "Creating rule '$RuleName' with $($CurrentChunk.Count) domains (~$CurrentLength chars)..." -ForegroundColor Yellow
        
        try {
            New-TransportRule -Name $RuleName `
                -Enabled $false `
                -SenderDomainIs $CurrentChunk `
                -ApplyHtmlDisclaimerLocation Prepend `
                -ApplyHtmlDisclaimerText $HtmlDisclaimer `
                -ApplyHtmlDisclaimerFallbackAction Wrap `
                -ErrorAction Stop | Out-Null
            
            Write-Host "✓ Successfully created rule $ChunkNumber" -ForegroundColor Green
            $SuccessfulRules++
        }
        catch {
            Write-Host "✗ Error creating rule ${ChunkNumber}: $_" -ForegroundColor Red
            Write-Host "  Attempted with $($CurrentChunk.Count) domains (~$CurrentLength chars)" -ForegroundColor Red
        }
        
        # Reset for next chunk
        $CurrentChunk = @()
        $CurrentLength = 0
        $ChunkNumber++
    }
    
    # Add domain to current chunk
    $CurrentChunk += $Domain
    $CurrentLength += $DomainLength
}

# Create the final rule for any remaining domains
if ($CurrentChunk.Count -gt 0) {
    $RuleName = "Add Disclaimer to Public Email Domains - Part $ChunkNumber"
    
    Write-Host "Creating rule '$RuleName' with $($CurrentChunk.Count) domains (~$CurrentLength chars)..." -ForegroundColor Yellow
    
    try {
        New-TransportRule -Name $RuleName `
            -Enabled $false `
            -SenderDomainIs $CurrentChunk `
            -ApplyHtmlDisclaimerLocation Prepend `
            -ApplyHtmlDisclaimerText $HtmlDisclaimer `
            -ApplyHtmlDisclaimerFallbackAction Wrap `
            -ErrorAction Stop | Out-Null
        
        Write-Host "✓ Successfully created rule $ChunkNumber" -ForegroundColor Green
        $SuccessfulRules++
    }
    catch {
        Write-Host "✗ Error creating rule ${ChunkNumber}: $_" -ForegroundColor Red
        Write-Host "  Attempted with $($CurrentChunk.Count) domains (~$CurrentLength chars)" -ForegroundColor Red
    }
}

# Summary
if ($SuccessfulRules -gt 0) {
    Write-Host "`n✓ Process complete! Created $SuccessfulRules transport rule(s)." -ForegroundColor Cyan
    Write-Host "✓ Rules now contain $($DomainArray.Count) domains from GitHub" -ForegroundColor Green
    Write-Host "All rules are DISABLED by default. Review and enable them in the Exchange Admin Center." -ForegroundColor Yellow
}
else {
    Write-Host "`n✗ Failed to create any rules." -ForegroundColor Red
}
