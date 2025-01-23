#2020.04.20 - @gwblok - GARYTOWN.COM
#Remediation Script
$ModuleName = "NuGet"
$LogFile = "$($env:Temp)\HP_Configuration Items.log"
#No Changes Below this Point ----------------------------

#region: CMTraceLog Function formats logging in CMTrace style
        function CMTraceLog {
         [CmdletBinding()]
    Param (
		    [Parameter(Mandatory=$false)]
		    $Message,
 
		    [Parameter(Mandatory=$false)]
		    $ErrorMessage,
 
		    [Parameter(Mandatory=$false)]
		    $Component = $ModuleName,
 
		    [Parameter(Mandatory=$false)]
		    [int]$Type,
		
		    [Parameter(Mandatory=$true)]
		    $LogFile
	    )
    <#
    Type: 1 = Normal, 2 = Warning (yellow), 3 = Error (red)
    #>
	    $Time = Get-Date -Format "HH:mm:ss.ffffff"
	    $Date = Get-Date -Format "MM-dd-yyyy"
 
	    if ($ErrorMessage -ne $null) {$Type = 3}
	    if ($Component -eq $null) {$Component = " "}
	    if ($Type -eq $null) {$Type = 1}
 
	    $LogMessage = "<![LOG[$Message $ErrorMessage" + "]LOG]!><time=`"$Time`" date=`"$Date`" component=`"$Component`" context=`"`" type=`"$Type`" thread=`"`" file=`"`">"
	    $LogMessage | Out-File -Append -Encoding UTF8 -FilePath $LogFile
    }

CMTraceLog -Message "----- Starting Remediation for Module $ModuleName -----" -Type 2 -LogFile $LogFile
[version]$RequiredVersion = (Find-PackageProvider -Name $ModuleName -Force).Version
$status = $null
$Status = Get-PackageProvider -Name $ModuleName -ErrorAction SilentlyContinue
if ($Status.Version -lt $RequiredVersion)
    {
    if ($Status){Uninstall-Module $ModuleName -AllVersions -Force}
    Write-Output "Installing $ModuleName to Latest Version $RequiredVersion"
    CMTraceLog -Message "Installing $ModuleName to Latest Version $RequiredVersion" -Type 1 -LogFile $LogFile
    Install-PackageProvider -Name $ModuleName -Force
    
    #Confirm
    $InstalledVersion = [Version](Get-PackageProvider -Name $ModuleName -ErrorAction SilentlyContinue).Version
    if (!($InstalledVersion)){$InstalledVersion = '1.0.0.1'}
    if ($InstalledVersion -lt $RequiredVersion)
        {
        Write-Output "Failed to Upgrade Module $ModuleName to $RequiredVersion"
        Write-Output "Currently on Version $InstalledVersion"
        CMTraceLog -Message "Failed to Upgrade Module $ModuleName to $RequiredVersion" -Type 3 -LogFile $LogFile
        CMTraceLog -Message "Currently on Version $InstalledVersion" -Type 3 -LogFile $LogFile
        }
    elseif ($InstalledVersion -ne $RequiredVersion)
        {
        Write-Output "Successfully Upgraded Module $ModuleName to $RequiredVersion"
        CMTraceLog -Message "Successfully Upgraded Module $ModuleName to $RequiredVersion" -Type 1 -LogFile $LogFile
        }
    }
else
    {
    Write-Output "$ModuleName already Installed with $($Status.Version)"
    CMTraceLog -Message "$ModuleName already Installed with $($Status.Version)" -Type 1 -LogFile $LogFile
    }

CMTraceLog -Message "----- Finished Remediation for Module $ModuleName -----" -Type 1 -LogFile $LogFile
