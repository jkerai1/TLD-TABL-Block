#Install-Module ExchangeOnlineManagement
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline
$BlockList = Invoke-WebRequest -URI 'https://www.info-sec.ca/tld-block.txt'| Select -expand Content
$exclusion = @('info','example')

foreach($line in $BlockList.Split([Environment]::NewLine)){
    if (-Not $line.StartsWith("#") -and ($exclusion -notcontains ($line))){
        Write-Host($line)
        $TLD = "*." + $line + "/*"
        New-TenantAllowBlockListItems -ListType Url -Block -Entries $TLD -NoExpiration -Notes "Blocked TLD https://www.info-sec.ca/tld-block.txt"
        }
}
