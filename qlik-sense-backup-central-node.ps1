#Requires -RunAsAdministrator

# MIT LICENSE - COPYRIGHT (c) 2018 QLIK SUPPORT
#
# THIS POWERSHELL SCRIPT IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY 
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT 
# OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE 
# USE OR OTHER DEALINGS IN THE SOFTWARE.

param (
    [string] $CentralNode  = $null,     # FQDN of central node
    [string] $BackupFolder = $null,     # Path to folder to store backup in
    [switch] $InstallQlikCLI = $false,  # Install Qlik CLI if missing
    [switch] $ExcludeArchiveLogs = $false,  # Exclude Archivelog fold from the backup  
    [System.Security.SecureString] $CertPassword = $null      # Certificate password 
)

# Prompt for backup folder if missing
# Validate path is valid, or break
if(-Not "$BackupFolder") {
    $BackupFolder = Read-Host -Prompt "Path to store backup"    
}
if(-Not (Test-Path "$BackupFolder")) { 
    Write-Host -ForegroundColor RED "Backup folder does not exists or is unavailable. Please confirm and try again. "
    break 
}


if(-Not "$CertPassword") {
    $CertPassword = Read-Host -Prompt "Certificate Password:"  -AsSecureString   
}

$StartTime = Get-Date -UFormat "%Y%m%d_%H%M"

Start-Transcript "$BackupFolder\QlikSenseBackup_$StartTime.log"
Set-ExecutionPolicy Bypass -Scope Process -Force

# Check if Qlik CLI is installed 
if (!(Get-Module -ListAvailable -Name Qlik-CLI)) {

    if ($InstallQlikCLI) {
        $PSVersion = $PSVersionTable.PSVersion.Major
        if($PSVersion -lt 4) {
            Write-Host -ForegroundColor Red "Qlik CLI requires PowerShell 4 or greater"
            Break   
        }elseif ($PSVersion -eq 4) {
            Write-Host -ForegroundColor Green "Downloading Qlik CLI files from GitHub..."
            New-Item "$Env:Programfiles\WindowsPowerShell\Modules\Qlik-Cli" -ItemType directory -Force
            Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ahaydon/Qlik-Cli/master/Qlik-Cli.psd1" -OutFile "$Env:Programfiles\WindowsPowerShell\Modules\Qlik-Cli\Qlik-Cli.psd1"
            Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ahaydon/Qlik-Cli/master/Qlik-Cli.psm1" -OutFile "$Env:Programfiles\WindowsPowerShell\Modules\Qlik-Cli\Qlik-Cli.psm1"
        }else {
            Write-Host -ForegroundColor Green "Qlik CLI installation from NuGet repository..."
            Set-ExecutionPolicy Bypass -Scope Process -Force
            Get-PackageProvider -Name NuGet -ForceBootstrap | Out-Null
            Install-Module -Name Qlik-CLI -Force  | Out-Null
        }
        Import-Module Qlik-Cli
        Write-Host -ForegroundColor Green "$((Get-Module Qlik-Cli).Name) ($((Get-Module Qlik-Cli).Version.Major).$((Get-Module Qlik-Cli).Version.Minor)) has been successfully installed"
    }else{
        Write-Host -ForegroundColor RED "Qlik-CLI is not installed. Add -InstallQlikCLI flag when calling this script, or install Qlik CLI from https://github.com/ahaydon/Qlik-Cli."
        break     
    }
}

# Create timestamps backup folder
$BackupFolder = "$BackupFolder\$StartTime"
New-Item "$BackupFolder" -itemtype directory -force

# Default node hostname to current hostname
if(!$CentralNode) {
    if(!$env:userdnsdomain) { $CentralNode = "$env:computername"                    }
    else                    { $CentralNode = "$env:computername.$env:userdnsdomain" }    
}

# Find Program Files path, by looking up QRD Install Location. Break if location can not be found
$QlikSenseProgramFiles = (Get-WmiObject -Class Win32_Product -Filter 'Name like "%qlik sense repository%"' | Select-Object InstallLocation).InstallLocation
if($QlikSenseProgramFiles -eq "") {
    Write-Host -ForegroundColor RED "Qlik Sense installation can not be found on this server. Please re-run this script on a Qlik Sense Central node."
    break
}

# Define pg_dump.exe path. Break if exe can not be found
$PgDumpExePath = $QlikSenseProgramFiles + "Repository\PostgreSQL\9.6\bin\pg_dump.exe"
if(![System.IO.File]::Exists($PgDumpExePath)){
    Write-Host -ForegroundColor RED "pg_dump.exe can not be found at default location;$PgDumpExePath"
    break
}

# Find persistence lcoaiton form QRS API
Connect-Qlik "$CentralNode"
$PersistenceRootFolder = (Get-QlikServiceCluster -id $((Get-QlikServiceCluster).id)).settings.sharedPersistenceProperties.rootFolder

# Stop Qlik Sense services prior to backup
$QlikServices = Get-Service "Qlik*" | Where-Object {($_.Name -like "QlikSense*" -and $_.Name -notlike "QlikSenseRepositoryDatabase") -or ($_.Name -eq "QlikLoggingService")}
$QlikServices | Stop-Service -Force 

# Dump repository DB to disk
Set-Location "$QlikSenseProgramFiles\Repository\PostgreSQL\9.6\bin\"
Invoke-Expression -Command ".\pg_dump.exe -h localhost -p 4432 -U postgres -b -F t -f ""$BackupFolder\QSR_backup.tar"" QSR"
#Invoke-Expression -Command """$PgDumpExePath"" -h localhost -p 4432 -U postgres -b -F t -f ""$BackupFolder\QSR_backup.tar"" QSR"


# Copy persistence storage folders to backup
# NOTE Archivelogs must be backup through qlik-sense-maintain-archived-logs.ps

if ($ExcludeArchiveLogs){
    $PersistenceSubFolders = ("Apps","CustomData","StaticContent")
} else {
    $PersistenceSubFolders = ("Apps", "ArchivedLogs", "CustomData","StaticContent")
}

foreach($subfolder in $PersistenceSubFolders) {
    robocopy $PersistenceRootFolder\$subfolder $BackupFolder\$subfolder /e
}




# Backup certificates
Get-ChildItem -Path cert:\CurrentUser\My\ | Where-Object {$_.Subject -like "*QlikClient"} | `
ForEach-Object { Export-PfxCertificate -cert $_ -FilePath "$BackupFolder$($_.Subject.Split(""="")[1]).pfx" -Password $CertPassword }

Get-ChildItem -Path cert:\LocalMachine\root\ | Where-Object {$_.Subject -like "*$env:computername*"} | `
ForEach-Object { Export-PfxCertificate -cert $_ -FilePath "$BackupFolder$($_.Subject.Split(""="")[1]).pfx" -Password $CertPassword }

Get-ChildItem -Path cert:\LocalMachine\My\ | Where-Object {$_.Subject -like "*$env:computername*"} | `
ForEach-Object { Export-PfxCertificate -Cert $_ -FilePath "$BackupFolder$($_.Subject.Split(""="")[1]).pfx" -Password $CertPassword }

# Start Qlik Services again
$QlikServices | Start-Service

Stop-Transcript