#Install-Module ExchangeOnlineManagement
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline
$BlockList = Invoke-WebRequest -URI 'https://raw.githubusercontent.com/cyb3rmik3/Hunting-Lists/main/spamhaus-abused-tlds.csv'| Select -expand Content

foreach($line in $BlockList.Split([Environment]::NewLine)){
    if (-Not $line.StartsWith("TLD")){
        $TLD = "*" + $line.Substring(0,$line.IndexOf(',')) + "/*"
        Write-Host($TLD)
        New-TenantAllowBlockListItems -ListType Url -Block -Entries $TLD -NoExpiration -Notes "Spamhaus commonly abused TLD. List maintained by cyb3rmik3"
        }
}
