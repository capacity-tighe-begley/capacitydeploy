#2020.04.20 - @gwblok - GARYTOWN.COM
#Discovery Script
$ModuleName = "PowerShellGet"

#No Changes Below this Point ----------------------------
[version]$RequiredVersion = (Find-PackageProvider -Name $ModuleName -Force).Version
$InstalledVersion = [Version](Get-PackageProvider -Name $ModuleName -ErrorAction SilentlyContinue).Version
if (!($InstalledVersion)){$InstalledVersion = '1.0.0.1'}
if ($InstalledVersion -ge $RequiredVersion){Write-Output "Compliant"}
else{
    Write-Output "Version: $InstalledVersion"
    exit 1
}
