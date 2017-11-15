# Hashtag voor commenting
# Whatif tonen
New-Item -ItemType File testnaam -WhatIf

Get-Verb
#Helaas op server bij nieuwe features opnieuw uitvoeren
Update-Help
#afhankelijk van uw dir
Get-ChildItem
Get-ChildItem c:\windows
#Registry bekijken
Get-Location
Set-Location HKCU:
Get-ChildItem 

#Directory inhoud bekijken
Get-ChildItem c:\windows *.inf -Recurse
Get-ChildItem "C:\users\<jouwusername>\Documents" –attributes directory
Get-item c:\windows
Get-childitem c:\windows

#De help leren gebruiken
Get-help Get-ChildItem
Get-help Get-ChildItem -Examples 
Get-help get-childitem -Parameter attributes

#Variabelen toekennen en gebruiken
$X = 123
Write-Host $X
#Doet hetzelfde als writehost
$X
# Variabelen hoeven niet "gedeclareerd" te worden
$X * 3 
#Resultaten van een cmdlet kunnen ook in een variabele worden gestoken
$Files = get-childitem "C:\program files\" -Include    
#Let op de verschillen
Write-host $files
$Files
#Inhoud files
$Files.Length
#voorrangsregels
#Zet in lijst.txt een aantal directories, 1 per lijn, zoals c:\windows, c:\program files, c:\
Get-ChildItem (Get-Content "c:\folder1\lijst.txt")

#Subexpressies
$service = Get-Service -Name Spooler
#Without the use of Sub-Expressions
"The Spooler Service is currently $service.status"
#Without the use of Sub-Expressions but extra step
$status = $service.status
"The Spooler Service is currently $status"
#With the use of Sub-Expressions
"The Spooler Service is currently $($service.status)" 

#Omdat VSC zich altijd standaard in de folder van de repository zet, set-location
Set-Location C:\Windows\System32
Get-ChildItem -Recurse | where lastwritetime -LT "02/01/2015"
# Old-fashioned way
Set-Location C:\Windows\System32
Get-childitem | where-object { $_.Lastwritetime -lt "01/01/2015" } 

#Hoe weet ik welke properties een bestand heeft ?
Set-Location C:\Windows\System32
Get-ChildItem | Get-Member

#Loops
2,3,4,16 | foreach { $_ * 3 }
#Basically hetzelfde
2,3,4,16 | foreach { $psitem * 3 } 
#Loops, op een andere manier
$Nrs= 2,3,4,16
ForEach ($Nr in $Nrs)
{
$Nr * 3
} 
# Loops en een piping!
$files = Get-ChildItem C:\Windows -File
foreach ($file in $files) {
$fileage = ((Get-Date) - $file.LastWriteTime)
"$($file.Name) = $fileage" | out-file C:\folder2\fileage.txt -Append
}


