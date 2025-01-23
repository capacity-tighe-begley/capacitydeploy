<#Future, Turn this into Params... well, that doesnt' really help as other steps need this information too...  we'll see
I would like to parameterize the "Version Field" so you could specify Manually, use a whitty one via a webcall, or nothing.

#>

$SiteCode = Get-ItemPropertyValue -Path HKLM:\SOFTWARE\OSDBuilder -Name SMSTSSiteCode
$ProviderMachineName = Get-ItemPropertyValue -Path HKLM:\SOFTWARE\OSDBuilder -Name SMSTSMP
$UpgradePackageID = Get-ItemPropertyValue -Path HKLM:\SOFTWARE\OSDBuilder -Name UpgradePackage
$OSDPackageID = Get-ItemPropertyValue -Path HKLM:\SOFTWARE\OSDBuilder -Name OSDPackage
$ReleaseID = Get-ItemPropertyValue -Path HKLM:\SOFTWARE\OSDBuilder -Name ReleaseID
$InstallationType = Get-ItemPropertyValue -Path HKLM:\SOFTWARE\OSDBuilder -Name InstallationType

Set-ExecutionPolicy Bypass -Force
#This Registry Key was se during Step 'Tag CMPSModule Path'


Write-Host "Loading CM PS Module" #First Check for Installed Console PowerShell, then Check for Package Contents to load Module
if ($env:SMS_ADMIN_UI_PATH)
    {
    Write-Output "Found CM Console in Path, trying to import module"
    Import-Module (Join-Path $(Split-Path $env:SMS_ADMIN_UI_PATH) ConfigurationManager.psd1)  
    if (Get-Module -Name ConfigurationManager){Write-Output "Successfully loaded CM Module from Installed Console"}
    $PSModulePath = $true
    }
else
    {
    try
        {
        $CMPSModulePath = Get-ItemPropertyValue -Path HKLM:\SOFTWARE\OSDBuilder -Name CMPSModulePath
        Write-Host $CMPSModulePath
        Import-Module (Join-Path $CMPSModulePath ConfigurationManager.psd1)
        if (Get-Module -Name ConfigurationManager)
            {Write-Output "Successfully loaded CM Module from Downloaded Source"
            $PSModulePath = $true
            }
        }
    catch{
        $PSModulePath = $false
        }
    }



if ($PSModulePath)
    {
    #Import-Module "$CMPSModulePath\ConfigurationManager.psd1"
    #Get SiteCode
    if (!(Get-PSDrive -Name $SiteCode -ErrorAction SilentlyContinue)){New-PSDrive -PSProvider CMSite -Name $SiteCode -Root $ProviderMachineName}
    Set-location $SiteCode":"
    
    #Capture Info about the Upgrade Package
    $UpgradePackage = Get-CMOperatingSystemUpgradePackage -Id $UpgradePackageID
    Set-ItemProperty -Path HKLM:\SOFTWARE\OSDBuilder -Name "PackSource_$($UpgradePackageID)" -Value $UpgradePackage.SourceVersion -Force
    Write-Host "$($UpgradePackage.Name) ID: $($UpgradePackage.PackageID)"
    Write-Host "$($UpgradePackage.ImageOSVersion)"

    
    #Capture Info about the OSD Package
    $OSDPackage = Get-CMOperatingSystemImage -id $OSDPackageID
    Set-ItemProperty -Path HKLM:\SOFTWARE\OSDBuilder -Name "PackSource_$($OSDPackageID)" -Value $OSDPackage.SourceVersion -Force
    Write-Host "$($OSDPackage.Name) ID: $($OSDPackage.PackageID)"
    Write-Host "$($OSDPackage.ImageOSVersion)"

    #Import OSDBuilder to grab content location of upgraded Media
    Import-Module OSDBuilder
    OSDBuilder -SetPath C:\OSBuildRoot\OSDBuilder
    $OSMedia = Get-OSMedia | Where-Object {$_.MediaType -eq "OSMedia" -and $_.ReleaseID -eq $ReleaseID -and $_.InstallationType -eq "$InstallationType"}

    #Copy Content to Source Server from Upgrade Local OSDBuilder Media (which includes the OSD Media)
    Set-Location c:
    write-host Rename $UpgradePackage.PkgSourcePath "$($UpgradePackage.PkgSourcePath).old"
    if (Test-Path -path "$($UpgradePackage.PkgSourcePath).old"){Remove-Item -Path "$($UpgradePackage.PkgSourcePath).old" -Recurse -Force}
    Rename-Item $UpgradePackage.PkgSourcePath "$($UpgradePackage.PkgSourcePath).old"
    new-item -Path $UpgradePackage.PkgSourcePath -ItemType Directory
    Write-Host "Coping Updated Media from OSBuilder to Source Server Pre-Prod Location for $ReleaseID"
    Remove-Item -Path "$($OSMedia.FullName)\OS\autorun.inf" -Force
    Copy-Item -Path "$($OSMedia.FullName)\OS\*" $UpgradePackage.PkgSourcePath -Recurse
    Copy-Item -Path "$($OSMedia.FullName)\WindowsImage.txt" "$($UpgradePackage.PkgSourcePath)\$($OSMedia.UBR).txt" -Force
    Set-ItemProperty -Path HKLM:\SOFTWARE\OSDBuilder -Name "UBR_$($InstallationType)_$($Releaseid)" -Value $OSMedia.UBR -Force
    Write-Host "Copy of $ReleaseID Content Finished"
    
    #Set Fun Version in CM Console for the Uploaded Media - Checks for "Holiday" and uses that. - @gwblok
    if ((Test-NetConnection "www.checkiday.com").PingSucceeded)
        {
        [xml]$Events = (New-Object System.Net.WebClient).DownloadString("https://www.checkiday.com/rss.php?tz=America/Chicago")
        if ($Events)
            {
            $EventNames = $Events.rss.channel.item.description
            #Pick Random Calendar Event
            [int]$Picker = Get-Random -Minimum 1 -Maximum $EventNames.Count
            $EventPicked = ($EventNames[$Picker]).'#cdata-section'
            $VersionName = ($EventPicked.Replace("Today is ","")).replace(" Day!"," Edition")
            if($VersionName.Contains('National')) {$VersionName = $VersionName.Replace("National","")}
        
            Write-Output "OSD Builder TS Version: $VersionName"
            }
        else
            {
            $VersionName = "BYO ISO Edition"
            Write-Output "No Special Events today, defaulting to generic"
            }
        }
    else
        {
        Write-Output "Can't Connect to Website"
        $VersionName = "BYO ISO Edition"
        Write-Output "No Special Events today, defaulting to generic"
        }


    #Trigger CM Updates
    Set-location $SiteCode":"
    Write-Host "Updating Image Properites & Updating DPs with new content"
    #Upgrade Media
    $UpgradePackage.ExecuteMethod("ReloadImageProperties", $null)
    Update-CMDistributionPoint -InputObject $UpgradePackage
    set-CMOperatingSystemInstaller -Id $UpgradePackage.PackageID -Description "OSDBuilder Build on $($OSMedia.ModifiedTime).  Built on Machine: $($env:COMPUTERNAME)"
    set-CMOperatingSystemInstaller -Id $UpgradePackage.PackageID -Version $VersionName
    #OSD Media
    $OSDPackage.ExecuteMethod("ReloadImageProperties", $null)
    Update-CMDistributionPoint -InputObject $OSDPackage
    Set-CMOperatingSystemImage -Id $OSDPackage.PackageID -Description "OSDBuilder Build on $($OSMedia.ModifiedTime).  Built on Machine: $($env:COMPUTERNAME)"
    Set-CMOperatingSystemImage -Id $OSDPackage.PackageID -Version $VersionName
    #Confirm Source Version Updated
    Start-Sleep -Seconds 180
    $UpgradePackageUpdated = Get-CMOperatingSystemUpgradePackage -Id $UpgradePackageID 
    

    $TimeOut = 1
    $TimeOutMax = 600
    $Message = "Checking WaaS Baseline Configuration Compliance"
    $Step = 1
    $MaxStep = 100
     do
        {
        If ($TimeOut -gt $TimeOutMax){break}
        Start-Sleep -Seconds 10
        $UpgradePackageUpdated = Get-CMOperatingSystemUpgradePackage -Id $UpgradePackageID 
        Write-Output "Orginal Package Source: $($UpgradePackage.SourceVersion), Currently: $($UpgradePackageUpdated.SourceVersion)"
        #$TimeOut
        $TimeOut++
        #$Step
        $Step++
        }
    until($UpgradePackageUpdated.SourceVersion -ne $UpgradePackage.SourceVersion)
    Set-ItemProperty -Path HKLM:\SOFTWARE\OSDBuilder -Name "PackSourceUpdated_$($UpgradePackageID)" -Value $UpgradePackageUpdated.SourceVersion -Force
    }
else
    {
    Write-Output "----------------------------------------------"
    Write-Output "NO CONFIGMGR POWERSHELL CommandLets AVAILABLE!"
    Write-Output "I wish I had checked for this much eariler in the process... could have saved me several hours"
    #Give me some time, I'll make this check at the start of the TS... just found this "BUG" and made a quick fix.
    EXIT 253

    }
