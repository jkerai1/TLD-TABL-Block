#Install-Module ExchangeOnlineManagement
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline

$BlockList = Invoke-WebRequest -URI 'https://raw.githubusercontent.com/jkerai1/TLD-TABL-Block/refs/heads/main/Abused%20TLDs.txt' | Select -expand Content
$exclusion = @('info','example')

foreach($line in $BlockList.Split([Environment]::NewLine)){
    # Trim whitespace and check if line is not empty, doesn't start with #, and isn't in exclusion list
    $trimmedLine = $line.Trim()
    
    if (-Not [string]::IsNullOrWhiteSpace($trimmedLine) -and 
        -Not $trimmedLine.StartsWith("#") -and 
        ($exclusion -notcontains $trimmedLine)){
        
        Write-Host($trimmedLine)
        $TLD = "*." + $trimmedLine
        New-TenantAllowBlockListItems -ListType Sender -Block -Entries $TLD -NoExpiration -Notes "Blocked TLD https://github.com/jkerai1/TLD-TABL-Block/tree/main"
    }
}
