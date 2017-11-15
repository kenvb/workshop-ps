$secpasswd = ConvertTo-SecureString "Labo1234567890" -AsPlainText -Force
$domainCred = New-Object System.Management.Automation.PSCredential ("bmoos.local\Administrator", $secpasswd)
$safemodeAdministratorCred = New-Object System.Management.Automation.PSCredential ("bmoos.local\Administrator", $secpasswd)
$localcred = New-Object System.Management.Automation.PSCredential ("Administrator", $secpasswd)
$newpasswd = ConvertTo-SecureString "Labo1234567890" -AsPlainText -Force
$userCred = New-Object System.Management.Automation.PSCredential ("bmoos.local\Administrator", $newpasswd)
$RootOU= "bmoos"
$Adapter = Get-NetAdapter
$RootShare="c:\shares"
$RootFRShare="c:\FolderRedirection"
$RootHFShare="c:\HomeFolders"

# Forgive me for the quirky, random code!

Configuration DC
{
    param()
    Import-DscResource -Modulename xNetworking
    Import-DscResource -ModuleName xActiveDirectory
    Import-DscResource -ModuleName xComputerManagement
    Import-DscResource –ModuleName PSDesiredStateConfiguration

    Node $AllNodes.Where{$_.Role -eq "Primary DC"}.Nodename
    {
    
        xComputer DCName
        {
        Name = "DC1"
        }
        xDhcpClient DisabledDhcpClient
        {
            State          = 'Disabled'
            InterfaceAlias = $Adapter.Name
            AddressFamily  = 'IPv4'
            DependsOn = '[xComputer]DCName'

        }

        xIPAddress StaticIPv4
        {

        IPAddress = "192.168.1.10/24"
        InterfaceAlias = $Adapter.Name
        AddressFamily = 'IPV4' 
        }
        xDnsServerAddress DnsServerAddress
        {
            Address        = '127.0.0.1'
            InterfaceAlias = $Adapter.Name
            AddressFamily  = 'IPv4'
            Validate       = $false
        }
      
        WindowsFeature ADDSInstall
        {
            Ensure = "Present"
            Name = "AD-Domain-Services"
            DependsOn = "[XDnsServerAddress]DnsServerAddress"
        }
        WindowsFeature MgmtTools
        {
        Ensure = "Present"
        Name =  "RSAT-ADDS"
        }
        xADDomain FirstDS
        {
            DomainName = $ConfigurationData.NonNodeData.DomainName
            DomainAdministratorCredential = $domainCred
            SafemodeAdministratorPassword = $safemodeAdministratorCred
            DependsOn = "[WindowsFeature]ADDSInstall","[WindowsFeature]MgmtTools"
        }
           

                File FRShare 
                {
                Type = 'Directory'
                DestinationPath = $RootFRShare
                Ensure = "Present"
        
                }
                  
    }

}

DC -configurationData .\scripts\configdata.psd1 -Verbose
write-verbose "Configuration for auto deployment built"
write-verbose "Launching autoconfiguration of Basic DC"