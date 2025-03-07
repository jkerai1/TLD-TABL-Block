#Install-Module ExchangeOnlineManagement
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline
$BlockList = Invoke-WebRequest -URI 'https://raw.githubusercontent.com/jkerai1/TLD-TABL-Block/refs/heads/main/OnionMail.txt'| Select -expand Content

foreach($line in $BlockList.Split("`n")){
    Write-Host($line)
    if (-Not $line.StartsWith("#")){
        New-TenantAllowBlockListItems -ListType Sender -Block -Entries $line -NoExpiration -Notes "OnionMail"
        }
}
