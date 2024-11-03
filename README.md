[![GitHub stars](https://img.shields.io/github/stars/jkerai1/TLD-TABL-Block?style=flat-square)](https://github.com/jkerai1/TLD-TABL-Block/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/jkerai1/TLD-TABL-Block?style=flat-square)](https://github.com/jkerai1/TLD-TABL-Block/network)
[![GitHub issues](https://img.shields.io/github/issues/jkerai1/TLD-TABL-Block?style=flat-square)](https://github.com/jkerai1/TLD-TABL-Block/issues)
[![GitHub pulls](https://img.shields.io/github/issues-pr/jkerai1/TLD-TABL-Block?style=flat-square)](https://github.com/jkerai1/TLD-TABL-Block/pulls)
# TLD-TABL-Block
Prevent emails containing URLs with abused TLDs with Tenant Allow Block List

Microsoft Documentation describing TLD blocking:  
https://learn.microsoft.com/en-us/microsoft-365/security/office-365-security/tenant-allow-block-list-urls-configure?view=o365-worldwide#scenario-top-level-domain-blocking  

# Example  

![image](https://github.com/jkerai1/TLD-TABL-Block/assets/55988027/e1e82995-ff6d-4942-998c-e2b2594efe38)


# Lists  

[Spamhaus List](https://github.com/cyb3rmik3/Hunting-Lists/)  ([original Source](https://www.spamhaus.org/statistics/tlds/)) 

[InfoSec CA List](https://www.info-sec.ca/tld-block.txt)


# Exchange Transport Rule For Senders Example - Modify as appropriate

Pattern: Includes these patterns in the From address: '\.(af|be|br|cn|ee|de|hu|ir|iq|it|jm|lv|lb|lt|kp|md|mm|nl|pl|ro|ru|kn|sy|tr|ua|uy|zip|top)$'  

![image](https://github.com/user-attachments/assets/bf41bdc4-70aa-4a5f-bf6d-ca23b405b95c)


# KQLs  

[KQL Search](https://www.kqlsearch.com/query/Topleveldomains&clmnymyzs00225i4sooju29dz)
```
EmailUrlInfo
| extend FQDN = trim_end("(:|\\?).*", tostring(split(trim_start('http(.|)://', UrlDomain), "/")[0]))
//| project-reorder FQDN, UrlDomain
| where FQDN contains "."  // exclude singular hostnames used in local name resolution
| extend TLD = tostring(split(FQDN, ".")[-1])
| summarize count() by TLD
```
Onion Mail  
```
let OnionMailAddresses = externaldata (onionmail: string) [@'https://raw.githubusercontent.com/jkerai1/TLD-TABL-Block/refs/heads/main/OnionMail.txt'] with (format=csv, ignoreFirstRecord=False);
EmailEvents
| where SenderFromDomain has_any (OnionMailAddresses)

```
Cockli  
```
let CockLiMailAddresses = externaldata (cocklimail: string) [@'https://raw.githubusercontent.com/jkerai1/TLD-TABL-Block/refs/heads/main/cockli-abused-Email-domains.txt'] with (format=csv, ignoreFirstRecord=False);
CockLiMailAddresses
EmailEvents
| where SenderFromDomain has_any (CockLiMailAddresses)
```
# See More

[Block TLDs in Windows Firewall via Intune](https://jeffreyappel.nl/block-gtld-zip-fqdn-domains-with-windows-firewall-and-defender-for-endpoint)  
