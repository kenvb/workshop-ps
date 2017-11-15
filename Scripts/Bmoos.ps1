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

Configuration BmoosBasic
{
    param()
    Import-DscResource -Modulename xNetworking
    Import-DscResource -ModuleName xActiveDirectory
    Import-DscResource -modulename xDHCpServer
    Import-DscResource -ModuleName xComputerManagement
    Import-DscResource –ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xsmbshare
    Import-DscResource -ModuleName cNtfsAccessControl

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
        xADDomainDefaultPasswordPolicy DDP
        {
        DomainName = $ConfigurationData.NonNodeData.DomainName
        MinPasswordLength =         "10"
        DependsOn = "[xADDomain]FirstDS"
        }
        WindowsFeature DHCP
        {
        Name = 'DHCP'
        Ensure = 'Present'
        DependsOn ="[xADDomain]FirstDS"
        IncludeAllSubFeature = $true

        }
            WindowsFeature RSATDHCP
            {
            name = "RSAT-DHCP"
            Ensure = "Present"
            DependsOn = @('[windowsfeature]DHCP')
            }
           xDhcpServerScope Scope 
           { 
            Ensure = 'Present'
            IPStartRange = '192.168.1.11' 
            IPEndRange = '192.168.1.200' 
            Name = 'BmoosScope' 
            SubnetMask = '255.255.255.0' 
            LeaseDuration = '00:08:00' 
            State = 'Active' 
            AddressFamily = 'IPv4'
            DependsOn = @('[WindowsFeature]DHCP') 

           } 
           xDhcpServerOption Option
            {
             Ensure = 'Present'
             ScopeID = '192.168.1.0'
             DnsDomain = 'bmoos.local'
             DnsServerIPAddress = '192.168.1.10'
             AddressFamily = 'IPv4'
             Router ='192.168.1.1' 
             DependsOn = @('[xDhcpServerScope]Scope')
            }
            xDhcpServerAuthorization Authorize
            {
            ensure = 'Present'
            IPAddress = "192.168.1.10"
            DnsName = "dc1.bmoos.local"

            DependsOn = @('[xDhcpServerOption]Option','[XADDomain]FirstDS')

            }
            xADOrganizationalUnit Moos
            {
            ensure = 'present'
            name =  $RootOU
            Path = 'dc=bmoos,dc=local'
            ProtectedFromAccidentalDeletion = $true
            DependsOn = '[xADDomain]FirstDS'
            }
            @($ConfigurationData.NonNodeData.OrganizationalUnits).foreach( {
            xADOrganizationalUnit "Bmoos$_"
                {
                    Ensure = 'Present'
                    Name = $_
                    Path = "ou=$RootOU,dc=bmoos,dc=local"
                    DependsOn = '[xADDomain]FirstDS','[xADOrganizationalUnit]Moos'
                    ProtectedFromAccidentalDeletion = $false
                }
            })
            @($ConfigurationData.NonNodeData.OrganizationalUnits2).foreach( {
            xADOrganizationalUnit "Users$_"
                {
                    Ensure = 'Present'
                    Name = $_
                    Path = "ou=Users, ou=$RootOU,dc=bmoos,dc=local"
                    DependsOn = '[xADDomain]FirstDS','[xADOrganizationalUnit]Moos'
                    ProtectedFromAccidentalDeletion = $false
                }
            })              

            @($ConfigurationData.NonNodeData.ADUsers).foreach( {

             xADUser "$($_.FirstName) $($_.LastName)"
                {
                    Ensure = 'Present'
                    DomainName = $ConfigurationData.NonNodeData.DomainName
                    GivenName = $_.FirstName
                    SurName = $_.LastName
                    UserName = ('{0}{1}' -f $_.FirstName.SubString(0, 1), $_.LastName)
                    UserPrincipalName = "$(('{0}{1}' -f $_.FirstName.SubString(0, 1), $_.LastName))@$($ConfigurationData.NonNodeData.DomainName)"
                    Department = $_.Department
                    Description = $_.Description
                    Path = "ou=$($_.Department), ou=users, ou=$RootOU,dc=bmoos,dc=local"
                   JobTitle = $_.Title
                    Password = $UserCred
                   HomeDirectory = $_.HomeDirectory
                   Homedrive = "$_.Homedrive\('{0}{1}' -f $_.FirstName.SubString(0, 1), $_.LastName)"
                    DependsOn = '[xADDomain]FirstDS'               
                }
            })

                @($ConfigurationData.Nonnodedata.AG).ForEach( {
                xadgroup "AGroup$($_.GGroup)"
                {
                Ensure = "present"
                Groupname = "GG$($_.GGroup)"
                GroupScope ="Global"
                Category = "Security"
                Description = "In deze groep zitten users en computers van de $($_.GGroup) afdeling"
                Path = "ou=GGroups, ou=$RootOU,dc=bmoos,dc=local"
                DependsOn = '[xADDomain]FirstDS'
                Memberstoinclude= $_.Include
                }
                }
                )      
             @($ConfigurationData.NonNodeData.GDLR).foreach( {
                xADGroup "DL$($_.DLGroup)R"
                {
                    Ensure = 'Present'
                    GroupName = "DL$($_.DLGroup)R"
                    GroupScope = "DomainLocal"
                    Description = "Members van deze groep hebben Read rechten op de $($_.DLGRoup) Share"
                    Category = "Security"
                    Path = "ou=DLGroups,ou=$RootOU,dc=bmoos,dc=local"
                    MembersToInclude = $_.Include
                    DependsOn = "[xADGroup]AGroupProductieTeamleaders"
                }
            })
                @($ConfigurationData.NonNodeData.GDLM).foreach( {
                xADGroup "DL$($_.DLGroup)M"
                {
                    Ensure = 'Present'
                    GroupName = "DL$($_.DLGroup)M"
                    GroupScope = "DomainLocal"
                    Description = "Members van deze groep hebben Modify rechten op de $($_.DLGRoup) Share"
                    Category = "Security"
                    Path = "ou=DLGroups,ou=$RootOU,dc=bmoos,dc=local"
                    MembersToInclude = $_.Include
                    DependsOn = "[xADGroup]AGroupProductieTeamleaders"
                }
            })
          

                File FRShare 
                {
                Type = 'Directory'
                DestinationPath = $RootFRShare
                Ensure = "Present"
        
                }
                Xsmbshare FRShareEnable
               {
                Ensure = "Present" 
                Name   = "FRShare"
                Path = "$RootFRShare"
                Description = "Share voor de FR. Niet Best Practice manier (security)"
                FullAccess = "Everyone"

               }
            
                File Shares 
                {
                Type = 'Directory'
                DestinationPath = $RootShare
                Ensure = "Present"
        
                }
                @($ConfigurationData.NonNodeData.shares).foreach( {
                File "Share$_"
                {
                    Ensure = 'Present'
                    DestinationPath = "$RootShare\$_"
                    Type = 'Directory'
                    DependsOn = '[File]Shares'
                }
            })
             File Boekhouding 
                {
                Type = 'Directory'
                DestinationPath = "$RootShare\Directie\Boekhouding"
                Ensure = "Present"
                DependsOn = '[File]ShareDirectie'
        
                }
                 File Werkschema 
                {
                Type = 'Directory'
                DestinationPath = "$RootShare\Productie\werkschema"
                Ensure = "Present"
                DependsOn = '[File]ShareProductie'
                }
                @($ConfigurationData.NonNodeData.shares).foreach( {
               Xsmbshare "EnableShare$_"
               {
                Ensure = "Present" 
                Name   = $_
                Path = "$RootShare\$_"
                Description = "Share voor de $_ afdeling"
                FullAccess = "Everyone"

               }
               })
               Xsmbshare EnableShareBoekhouding
               {
                Ensure = "Present" 
                Name   = "Boekhouding"
                Path = "$RootShare\Directie\Boekhouding"
                Description = "Share voor de boekhouder. Niet Best Practice manier."
                FullAccess = "Everyone"

               }

                 @($ConfigurationData.NonNodeData.shares).foreach( {
                CntfsPermissionEntry "READ$_"
                {
                    path="C:\shares\$_"
                    Principal = "bmoos\DL$_"+"R"
                    
                    AccessControlInformation = @(
                    cNtfsAccessControlInformation
                    {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'ReadAndExecute'
                    Inheritance = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false
                    }
                     )}
                     })

                @($ConfigurationData.NonNodeData.shares).foreach( {
                CntfsPermissionEntry "MODIFY$_"
                {
                    path="C:\shares\$_"
                    Principal = "bmoos\DL$_"+"M"
                    
                    AccessControlInformation = @(
                    cNtfsAccessControlInformation
                    {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'Modify'
                    Inheritance = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false
                    }
                     )}
                     })
                cNtfsPermissionsInheritance DisableInheritanceShares
                {
                    Path = $RootShare
                    Enabled = $false
                    PreserveInherited = $true
                    DependsOn = '[File]Shares'

                }

                cNtfsPermissionEntry RemoveAuthUsers
                {
                    Ensure = 'Absent'
                    Path = $RootShare
                    Principal = 'NT AUTHORITY\Authenticated Users'
                    DependsOn = '[File]Shares'
                }
                cNtfsPermissionEntry RemoveUsers
                {
                    Ensure = 'Absent'
                    Path = $RootShare
                    Principal = "Users"
                    DependsOn = '[File]Shares'
                }
                cNtfsPermissionsInheritance DisableInheritanceWerkschema
                {
                    Path = "$Rootshare\productie\werkschema"
                    Enabled = $false
                    PreserveInherited = $false
                    DependsOn = '[File]Shares'
                }
                CntfsPermissionEntry "READWerkschema"
                    {
                    path="$Rootshare\productie\werkschema"
                    Principal = "bmoos\DLWerkschemaR"
                    AccessControlInformation = @(
                    cNtfsAccessControlInformation
                    {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'ReadAndExecute'
                    Inheritance = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false
                    })
                    }
                    CntfsPermissionEntry "ModifyWerkschema"
                    {
                    path="$Rootshare\productie\werkschema"
                    Principal = "bmoos\DLWerkschemaM"
                    AccessControlInformation = @(
                    cNtfsAccessControlInformation
                    {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'Modify'
                    Inheritance = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false
                    })
                    }
                     CntfsPermissionEntry "FCWerkschema"
                    {
                    path="$Rootshare\productie\werkschema"
                    Principal = "bmoos\Domain Admins"
                    AccessControlInformation = @(
                    cNtfsAccessControlInformation
                    {
                    AccessControlType = 'Allow'
                    FileSystemRights = "FullControl"
                    Inheritance = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false
                    })
                    }

                File HomeFolder
                {
                DestinationPath = $RootHFShare
                Ensure = "present"
                Type = "Directory"
                }
               xSmbShare Homefoldershare
               {
               path="$RootHFShare"
               Name = "HomeFolder"
               FullAccess = "Everyone"
               dependson= '[File]HomeFolder'
               }
        Script GPOLINK            
        {                  
            GetScript = {            
                Return @{            
                    Result = [string]$(Get-ADOrganizationalUnit -Filter 'Name -like "*"' | FT Name, DistinguishedName -A)            
                }            
            }            
                 
            TestScript = {            
                If ((Get-ADOrganizationalUnit -Filter 'Name -like "*"' | FT Name, DistinguishedName -A ) -like "*OU=Users,OU=bmoos,DC=bmoos,DC=local*") {            
                    Write-Verbose "OU's are present"            
                    Return $true
                } Else {            
                    Write-Verbose "OU's not present"            
                    Return $False           
                }            
            }            
                     
            SetScript = {            
                Write-Verbose "Creating and adding GPO"            
                Import-GPO -BackupGpoName "GPO_Redirected Folders" -Path C:\Users\Administrator\Documents\GPO -TargetName RedirectedFolders -CreateIfNeeded
                New-GPLink -Name RedirectedFolders -Target "ou=users,ou=bmoos,dc=bmoos,dc=local" -LinkEnabled yes        
            }
           DependsOn = '[xADDomain]FirstDS','[xADOrganizationalUnit]Moos'            
        }

        # Sadly, the dhcp post deployment notification won't dissapear. At least everything is functional!
        Script DHCPSecurityGroup            
        {            
           
            GetScript = {            
                Return @{            
                    Result = [string]$(Get-ADGroup -Filter 'Name -like "*"' | ft name -A)            
                }            
            }            
            
          
            TestScript = {            
                If ((Get-ADGroup -Filter 'Name -like "*"' | FT Name, DistinguishedName -A ) -like "*dhcp*") {            
                    Write-Verbose "OU's are present"            
                    Return $true
                } Else {            
                    Write-Verbose "OU's not present"            
                    Return $False           
                }            
            }            
            
       
            SetScript = {            
                Write-Verbose "Creating DHCP Server Security Group"            
                Add-DhcpServerSecurityGroup       
            }
           DependsOn = '[xADDomain]FirstDS','[xDhcpServerAuthorization]Authorize'        
        }                     
               
                

                  
    }

}

Bmoosbasic -configurationData .\scripts\configdata.psd1 -Verbose
write-verbose "Configuration for auto deployment built"
write-verbose "Launching autoconfiguration of Brouwerij Moos"