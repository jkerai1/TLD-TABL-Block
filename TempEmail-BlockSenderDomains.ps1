#Install-Module ExchangeOnlineManagement
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline
$BlockList = Invoke-WebRequest -URI 'https://raw.githubusercontent.com/jkerai1/TLD-TABL-Block/refs/heads/main/tempmail-abused%20emaildomains.txt'| Select -expand Content

foreach($line in $BlockList.Split("`n")){
    Write-Host($line)
    if (-Not $line.StartsWith("#") -And ($line.Length -ge 2)){
        New-TenantAllowBlockListItems -ListType Sender -Block -Entries $line -NoExpiration -Notes "Temporary Email"
        }
}
