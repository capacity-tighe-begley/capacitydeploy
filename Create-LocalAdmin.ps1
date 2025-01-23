$LoggedOnUsers = (Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object UserName).UserName.Split('\')[1]
foreach($user in $LoggedOnUsers){
    New-LocalUser -Name "l-$user" -AccountNeverExpires -PasswordNeverExpires
    Add-LocalGroupMember -Member "l-$user" -Group "Administrators"
}