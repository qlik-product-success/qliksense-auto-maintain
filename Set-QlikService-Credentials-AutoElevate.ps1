# Self elevate to administrator mode if needed
if(![bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")) {
    $MyInvocation.MyCommand.Path
    Start-Process PowerShell -verb runas -ArgumentList '-NoExit', '-File',$MyInvocation.MyCommand.Path #, "$args"
    break
} 

# Input dialog to request new service credentials
Write-Host -ForegroundColor Green "Changing service credentials to "
$Credential = Get-Credential -message "`nProvide credentials to apply for Qlik Sense services.`n"
Write-Host -ForegroundColor Green -NoNewLine "$($Credential.UserName.ToUpper()) for Qlik Sense services..."

# Qlik Sense servces to apply new credentials on
# Exclude QRD service, as it runs with Local System

#$QlikServices = Get-Service "QlikSense*" | where {$_.Name -notlike "QlikSenseRepositoryDatabase"}
$QlikServices = Get-Service "Qlik*" | Where-Object {($_.Name -like "QlikSense*" -and $_.Name -notlike "QlikSenseRepositoryDatabase") -or ($_.Name -eq "QlikLoggingService")}
$QlikServices.DisplayName

# Stop all Qlik Sense services 
# Include services that have name starting with QlikSense
# Exclude Repository Database as it is expected to run as Local System

$QlikServices | Stop-Service -Force 

# Set same new service credentail for all services
$QlikServices | ForEach-Object{ (Get-WMIObject Win32_Service -Filter "Name='$($_.Name)'").change($null,$null,$null,$null,$null,$null, $Credential.UserName,$Credential.GetNetworkCredential().Password,$null,$null,$null)}

# Start all services again
$QlikServices | Start-Service 

# Wait for key press
Write-Host -ForegroundColor Green -NoNewLine "DONE! Check that services are running with expected credentials. Press any key to continue... "
#$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")