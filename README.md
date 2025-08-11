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

![image](https://github.com/user-attachments/assets/69a5971c-8f69-45b4-8b27-9e419cb8ffa6)

# Lists  

[Spamhaus List](https://github.com/cyb3rmik3/Hunting-Lists/)  ([original Source](https://www.spamhaus.org/statistics/tlds/)) 

[InfoSec CA List](https://www.info-sec.ca/tld-block.txt)
> Run [KQLs](https://github.com/jkerai1/TLD-TABL-Block?tab=readme-ov-file#kqls) first before deploying to minimize business impact  

# Sender Domains  

After releasing this repo I decided to add functionality to block sender domains too in TABL

Currently these include:
- OnionMail
- CockLi
- Temp Email Addresses (list heavily based of https://github.com/disposable/disposable)

> This will **ONLY** block the Sender Domain and not emails containing URL, however I leave this to the viewer you'd just need to copy the functionality from the TLD TABL Url Script.

The Temp Email list is large, I would **only** recommend deploying this if you have Defender for Office P2 as it exceeds the limit for plan 1.  

"Defender for Office 365 Plan 2: The maximum number of allow entries is 5000, and the maximum number of block entries is 10000 (15000 domain and email address entries in total)."  
> Ref https://learn.microsoft.com/en-us/defender-office-365/tenant-allow-block-list-email-spoof-configure?view=o365-worldwide#what-do-you-need-to-know-before-you-begin

# Exchange Transport Rule For Senders Example - Modify as appropriate
> TLDs are now supported for Domain Senders in TABL so I would recommend using that instead and not using the Exchange Transport for anything other than auditing Ref :https://learn.microsoft.com/en-us/defender-office-365/tenant-allow-block-list-email-spoof-configure#what-do-you-need-to-know-before-you-begin <img width="1082" height="117" alt="image" src="https://github.com/user-attachments/assets/750265ec-76f0-418a-9060-c52f2d5b1821" />


Pattern: Includes these patterns in the From address: '\.(af|be|br|cn|ee|de|hu|ir|iq|it|jm|lv|lb|lt|kp|md|mm|nl|pl|ro|ru|kn|sy|tr|ua|uy|zip|top)$'  

![image](https://github.com/user-attachments/assets/bf41bdc4-70aa-4a5f-bf6d-ca23b405b95c)

# Remote Domains Example  

Extra layer against autoforwarding persistence attack  

![image](https://github.com/user-attachments/assets/89f7d919-0e9d-4543-8f6a-91fdbe866f00)

![image](https://github.com/user-attachments/assets/cc422091-94a8-4d71-a148-502b9871bb91)  

# KQLs  
> Many of my KQLs are already on [KQLsearch](https://www.kqlsearch.com/)

[Connections to abused TLDs -KQL Search](https://www.kqlsearch.com/query/Topleveldomains&clmnymyzs00225i4sooju29dz)  
[TLD Count](https://github.com/jkerai1/KQL-Queries/blob/main/Defender/TLD%20by%20Count%20for%20DeviceNetworkEvents.kql)

Emails by TLD (URLs)  

```
EmailUrlInfo
| extend FQDN = trim_end("(:|\\?).*", tostring(split(trim_start('http(.|)://', UrlDomain), "/")[0]))
//| project-reorder FQDN, UrlDomain
| where FQDN contains "."  // exclude singular hostnames used in local name resolution
| extend TLD = tostring(split(FQDN, ".")[-1])
| summarize count() by TLD
```

Emails by TLD (Senders)  

```
EmailEvents
| extend FQDN = trim_end("(:|\\?).*", tostring(split(trim_start('http(.|)://', SenderFromDomain), "/")[0]))
//| project-reorder FQDN, UrlDomain
| where FQDN contains "."  // exclude singular hostnames used in local name resolution
| where DeliveryAction == "Delivered"
| extend TLD = tostring(split(FQDN, ".")[-1])
| summarize count() by TLD, EmailDirection
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
EmailEvents
| where SenderFromDomain has_any (CockLiMailAddresses)
```
Temp Mail
```
let TempEmailAddresses = externaldata (mail: string) [@'https://raw.githubusercontent.com/jkerai1/TLD-TABL-Block/refs/heads/main/tempmail-abused%20emaildomains.txt'] with (format=csv, ignoreFirstRecord=False);
EmailEvents
| where TimeGenerated > ago(90d)
| where SenderFromDomain has_any (TempEmailAddresses) or RecipientEmailAddress has_any(TempEmailAddresses)
//| join kind=leftouter EmailUrlInfo on NetworkMessageId
//| summarize make_list(Url) by NetworkMessageId,SenderFromAddress, RecipientEmailAddress, Subject, AttachmentCount, UrlCount
```
# See More

[Block TLDs in Windows Firewall via Intune](https://jeffreyappel.nl/block-gtld-zip-fqdn-domains-with-windows-firewall-and-defender-for-endpoint)  

![image](https://github.com/user-attachments/assets/64251c0a-3048-43ff-80d0-0619fc632ac7)

![image](https://github.com/user-attachments/assets/ab0a4dc5-5dd3-41cc-86f1-45ac81883b94)

![image](https://github.com/user-attachments/assets/4969046c-d914-4151-912f-143ffadaa42f)

![image](https://github.com/user-attachments/assets/f826253f-3eff-47fa-81a4-54239aa52f0c)
