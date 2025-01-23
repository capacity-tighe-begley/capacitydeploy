<#
Script to update BIOS Settings for HP Desktop Devices by Gary Blok

Script Code References:
https://github.com/svenriebedell/Intune/tree/main/Remediation
https://garytown.com/hp-bcu-to-hp-cmsl

Version Changes

    24.09.24 - Gary Blok Initial Version



.Synopsis
    This PowerShell is checking BIOS setting are compliant to IT requirements
    IMPORTANT: This script does not reboot the system to apply or query system.
.DESCRIPTION
    Powershell using WMI and read the existing BIOS settings and compare with IT required
#>

#Variables


#region Functions
#########################################################################################################
####                                    Function Section                                             ####
#########################################################################################################




Function Get-ChassisType {
    <#
    .SYNOPSIS
    This function returns the Chassis Type of the device
    .DESCRIPTION
    This function returns the Chassis Type of the device
    .EXAMPLE
    Get-ChassisType
    #>
    $DesktopChassisTypes = @("3", "4", "5", "6", "7", "13", "15", "16", "35")
    $LatopChassisTypes = @("8", "9", "10", "11", "12", "14", "18", "21", "30", "31")
    $ChassisType = Get-CimInstance -ClassName Win32_SystemEnclosure | Select-Object -ExpandProperty ChassisTypes 
    if ($ChassisType -in $LatopChassisTypes) {
        return "Laptop"
    }
    elseif ($ChassisType -in $DesktopChassisTypes) {
        return "Desktop"
    }
    else {
        return $ChassisType 
    }
}

Function Get-Manufacturer {
    <#
    .SYNOPSIS
    This function returns the Manufacturer of the device
    .DESCRIPTION
    This function returns the Manufacturer of the device
    .EXAMPLE
    Get-Manufacturer
    #>
    $Baseboard = Get-CimInstance -ClassName Win32_Baseboard
    If ($Baseboard.Manufacturer -match "Dell") {
        return "Dell"
    }
    ElseIf ($Baseboard.Manufacturer -match "HP" -or $Baseboard.Manufacturer -match "Hewlett") {
        return "HP"
    }
    else {
        return $Baseboard.Manufacturer 
    }
}


#endregion

#########################################################################################################
####                                    Varible Section                                              ####
#########################################################################################################


$Compliance = $True
$TranscriptPath = "$env:SystemDrive\Windows\Temp\BIOSManagement-Remediation.log"
$BIOSCompliant = @(
    [PSCustomObject]@{BIOSSettingName = "Fast Boot"; BIOSSettingValue = "Enable" }
    [PSCustomObject]@{BIOSSettingName = "Startup Delay (sec.)"; BIOSSettingValue = "0" }
    [PSCustomObject]@{BIOSSettingName = "S5 Maximum Power Savings"; BIOSSettingValue = "Disable" }  
    [PSCustomObject]@{BIOSSettingName = "After Power Loss"; BIOSSettingValue = "Power On" }
    [PSCustomObject]@{BIOSSettingName = "Wake On LAN"; BIOSSettingValue = "Boot to Hard Drive" }
    [PSCustomObject]@{BIOSSettingName = "NumLock on at boot"; BIOSSettingValue = "Enable" }  
)

$Manufacturer = Get-Manufacturer
$ChassisType = Get-ChassisType
$IntendedManufacturer = "HP"
$IntendedChassisType = "Desktop"

#########################################################################################################
####                                    Program Section                                              ####
#########################################################################################################


Start-Transcript -Path $TranscriptPath -Append
Write-Output "Starting BIOS Remediation Script on $Manufacturer $ChassisType Device"
Write-Output "Intended Manufacturer: $IntendedManufacturer & Intended Chassis Type: $IntendedChassisType"

#PreChecks
If ($Manufacturer -notmatch $IntendedManufacturer) {
    Write-Output "Manufacturer is not $IntendedManufacturer, exiting script"
    Stop-Transcript
    Exit 0
}
if ($ChassisType -ne $IntendedChassisType) {
    Write-Output "Chassis Type is not $IntendedChassisType, exiting script"
    Stop-Transcript
    Exit 0
}


#Connect to WMI Interface
$BiosSettings = Get-CimInstance  -Namespace root/HP/InstrumentedBIOS -ClassName HP_BIOSEnumeration

# get BIOS setting from device
try {
    [array]$BIOSCompliantStatus = @()
        
    foreach ($Setting in $BIOSCompliant) {
        # Temp Array
        $TempBIOSStatus = New-Object -TypeName psobject
                
        $TempBIOSStatus = $BiosSettings | Where-Object { $_.Name -eq $Setting.BIOSSettingName } -ErrorAction Stop | Select-Object Name, CurrentValue
            
        [array]$BIOSCompliantStatus += $TempBIOSStatus
    }
}
catch {
    Write-Host "Get BIOS settings failed"
    Stop-Transcript
    Exit 1
}
# check setting compliants
[array]$SettingCompliant = @()

foreach ($Status in $BIOSCompliantStatus) {
        
    $TempSettingCompliant = New-Object -TypeName psobject

    ForEach ($Compliant in $BIOSCompliant) {
        If ($Compliant.BIOSSettingName -eq $Status.Name) {
                        

            If ($Compliant.BIOSSettingValue -eq $Status.CurrentValue) {
                $TempSettingCompliant | Add-Member -MemberType NoteProperty -Name Name -Value $Status.Name
                $TempSettingCompliant | Add-Member -MemberType NoteProperty -Name Compliant -Value $true

            }
            else {
                $TempSettingCompliant | Add-Member -MemberType NoteProperty -Name Name -Value $Status.Name
                $TempSettingCompliant | Add-Member -MemberType NoteProperty -Name Compliant -Value $false
            }
        }    	
    }
    $SettingCompliant += $TempSettingCompliant
}



# if one or more settings not compliant Exit 1 other otherwise Exit 0

foreach ($Compliant in $SettingCompliant) {
    if ($Compliant.Compliant -eq $true) {
        Write-Host $Compliant.Name "is compliant" -ForegroundColor Green
    }
    else {   
        $Compliance = $False
        Write-Host $Compliant.Name "is NOT compliant" -ForegroundColor Red

    }
}
if ($Compliance -eq $False) {
    Write-Host "BIOS settings are not compliant" -ForegroundColor Red
    Stop-Transcript
    Exit 1
}
else {
    Write-Host "BIOS settings are compliant" -ForegroundColor Green
    Stop-Transcript
    Exit 0
}
#########################################################################################################
####                                    END                                                          ####
#########################################################################################################