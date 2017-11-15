[cmdletbinding()]
Param()
# Internet connectiviteit is nodig
Write-Verbose "Brouwerij Moos. Orchestrated by Ken Vanden Branden. Enjoy the music."
Write-Verbose "Installing Modules for Brouwerij Moos exercise"
Install-PackageProvider -name NuGet -Force
install-module xnetworking -force -verbose
install-module xComputerManagement -force -verbose
Install-Module -Name xActiveDirectory -force -verbose
Write-Verbose "Modules Installed"
Write-warning "LET OP!"
write-verbose "Verander NU je NIC-instellingen naar'host only' of iets dergelijks."
Write-Verbose "Klik op ENTER wanneer je dit gedaan hebt om verder te gaan"
Pause