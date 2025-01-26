# Apply registry mods to prevent reinstallation and disable features
function Set-AppsRegistry {
    $MultilineComment = @"
Windows Registry Editor Version 5.00

; --Application and Feature Restrictions--

; Disable Windows Copilot system-wide
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot]
"TurnOffWindowsCopilot"=dword:00000001

; Prevents Dev Home Installation
[-HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\DevHomeUpdate]

; Prevents New Outlook for Windows Installation
[-HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate]

; Prevents Chat Auto Installation
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Communications]
"ConfigureChatAutoInstall"=dword:00000000

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Windows Chat]
"ChatIcon"=dword:00000003

; Disables Cortana
[HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\Windows Search]
"AllowCortana"=dword:00000000

; Disables OneDrive Automatic Backups of Important Folders (Documents, Pictures etc.)
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\OneDrive]
"KFMBlockOptIn"=dword:00000001
"@
    Set-Content -Path "$env:TEMP\Windows_Apps.reg" -Value $MultilineComment -Force -ErrorAction SilentlyContinue
    Regedit.exe /S "$env:TEMP\Windows_Apps.reg" -Force -ErrorAction SilentlyContinue
}

# Removes OneDrive during Windows Installation
function Remove-OneDrive {
    Remove-Item "C:\Users\Default\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk" -ErrorAction SilentlyContinue
    Remove-Item "C:\Users\Default\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.exe" -ErrorAction SilentlyContinue
    Remove-Item "C:\Windows\System32\OneDriveSetup.exe" -ErrorAction SilentlyContinue
    Remove-Item "C:\Windows\SysWOW64\OneDriveSetup.exe" -ErrorAction SilentlyContinue
}

# Uninstalls OneDrive in existing Windows Installation
function Uninstall-OneDrive {
    # stop onedrive running
    Stop-Process -Force -Name OneDrive -ErrorAction SilentlyContinue | Out-Null
    # uninstall onedrive w10
    cmd /c "C:\Windows\SysWOW64\OneDriveSetup.exe -uninstall >nul 2>&1"
    # clean onedrive w10 
    Get-ScheduledTask | Where-Object { $_.Taskname -match 'OneDrive' } | Unregister-ScheduledTask -Confirm:$false
    # uninstall onedrive w11
    cmd /c "C:\Windows\System32\OneDriveSetup.exe -uninstall >nul 2>&1"
}

# Disables Recall
function Disable-Recall {
    Dism /Online /Disable-Feature /Featurename:Recall /NoRestart | Out-Null
}

# function Remove-Apps {
#     # Bloatware Apps
#     Get-AppxPackage -AllUsers | Where-Object { $appxPackages -contains $_.Name } | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Out-Null
#     # Legacy Windows Features & Apps
#     Get-WindowsCapability -Online | Where-Object { $capabilities -contains ($_.Name -split '~')[0] } | Remove-WindowsCapability -Online -ErrorAction SilentlyContinue | Out-Null

#     $appxPackages = @(
#     'Microsoft.Microsoft3DViewer', 'Microsoft.BingSearch', 'Microsoft.WindowsCamera', 'Clipchamp.Clipchamp',
#     'Microsoft.WindowsAlarms', 'Microsoft.549981C3F5F10', 'Microsoft.Windows.DevHome',
#     'MicrosoftCorporationII.MicrosoftFamily', 'Microsoft.WindowsFeedbackHub', 'Microsoft.GetHelp',
#     'microsoft.windowscommunicationsapps', 'Microsoft.WindowsMaps', 'Microsoft.ZuneVideo',
#     'Microsoft.BingNews', 'Microsoft.MicrosoftOfficeHub', 'Microsoft.Office.OneNote',
#     'Microsoft.OutlookForWindows', 'Microsoft.People', 'Microsoft.Windows.Photos',
#     'Microsoft.PowerAutomateDesktop', 'MicrosoftCorporationII.QuickAssist', 'Microsoft.SkypeApp',
#     'Microsoft.MicrosoftSolitaireCollection', 'Microsoft.MicrosoftStickyNotes', 'MSTeams',
#     'Microsoft.Getstarted', 'Microsoft.Todos', 'Microsoft.WindowsSoundRecorder', 'Microsoft.BingWeather',
#     'Microsoft.ZuneMusic', 'Microsoft.WindowsTerminal', 'Microsoft.Xbox.TCUI', 'Microsoft.XboxApp',
#     'Microsoft.XboxGameOverlay', 'Microsoft.XboxGamingOverlay', 'Microsoft.XboxIdentityProvider',
#     'Microsoft.XboxSpeechToTextOverlay', 'Microsoft.GamingApp', 'Microsoft.YourPhone', 'Microsoft.OneDrive',
#     'Microsoft.549981C3F5F10', 'Microsoft.MixedReality.Portal', 'Microsoft.ScreenSketch'
#     'Microsoft.Windows.Ai.Copilot.Provider', 'Microsoft.Copilot', 'Microsoft.Copilot_8wekyb3d8bbwe',
#     'Microsoft.WindowsMeetNow', 'Microsoft.WindowsStore', 'Microsoft.Paint', 'Microsoft.MSPaint'
# )

#     # Define Windows Capabilities
#     $capabilities = @(
#     'Browser.InternetExplorer', 'MathRecognizer', 'OpenSSH.Client',
#     'Microsoft.Windows.PowerShell.ISE', 'App.Support.QuickAssist', 'App.StepsRecorder',
#     'Media.WindowsMediaPlayer', 'Microsoft.Windows.WordPad', 'Microsoft.Windows.MSPaint'
# )
# }

Set-ExecutionPolicy -ExecutionPolicy Bypass

Set-AppsRegistry
Remove-OneDrive
Uninstall-OneDrive
Disable-Recall
# Remove-Apps