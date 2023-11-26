Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline
$BlockList = Invoke-WebRequest -URI 'https://www.info-sec.ca/tld-block.txt'| Select -expand Content

foreach($line in $BlockList.Split([Environment]::NewLine)){
    Write-Host($line)
    if (-Not $line.StartsWith("#")){
        $TLD = "*." + $line + "/*"
        New-TenantAllowBlockListItems -ListType Url -Block -Entries $TLD -NoExpiration -Notes "Blocked TLD https://www.info-sec.ca/tld-block.txt"
        }
}
