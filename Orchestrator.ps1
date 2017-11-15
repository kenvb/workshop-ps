#Requires -Version 5.1
.\scripts\Install-Modules.ps1 -Verbose
.\scripts\Prepare-LCM.ps1
Set-DscLocalConfigurationManager .\LCM
.\Scripts\DC.ps1
Start-DscConfiguration .\DC -Verbose -Force
Pause