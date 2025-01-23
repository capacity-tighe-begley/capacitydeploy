<#  GARY BLOK - @gwblok - GARYTOWN.COM
https://garytown.com/hp-sure-recover-custom-setup-part-1-overview


Installed OpenSSL Light on my desktop: https://slproweb.com/products/Win32OpenSSL.html


GUIDES Used in creation of this script content:

    Initiallizing SPM (Secure Platform Module):
    https://developers.hp.com/hp-client-management/blog/hp-secure-platform-management-hp-client-management-script-library

    Sure Recover Doc: http://h10032.www1.hp.com/ctg/Manual/c06579216.pdf

    Provisioning and Configuring HP Sure Recover with HP Client Management Script Library
    https://developers.hp.com/hp-client-management/blog/provisioning-and-configuring-hp-sure-recover-hp-client-management-script-library

    Provisioning a HP Sure Recover Custom Image in a Modern Managed Cloud Environment
    https://developers.hp.com/hp-client-management/blog/provisioning-hp-sure-recover-custom-image-modern-managed-cloud-environment





THINGS YOU NEED TO DO:
Figure out where you want to store this stuff, I'd recommend a file server, and backups, as you won't want to lose the certs you'll be creating.
Folder Stucture: (Will be auto generated by this script)

Root\SureRecover\$Build\

Copy your Image (WIM FILE) to the $ImagePath (Root\SureRecover\$Build)
I'm using the build Number as my Directory Structure (22621)
    example: C:\HP\SureRecover\22621\Split


Have your Web Server ready (or Azure Blob)
Update the $URL below to where you move your $Split folder contents to, along with the manifest file and manifest signature


Once you've created your payload files, you can deploy them to your test machine
Set-HPSecurePlatformPayload -PayloadFile "$SureRecoverWorkingpath\SPEKPP.dat"
Set-HPSecurePlatformPayload -PayloadFile "$SureRecoverWorkingpath\SPSKPP.dat"
Set-HPSecurePlatformPayload -PayloadFile "$SureRecoverWorkingpath\OSpayload.dat"


#>

#$URL = "http://hpsr.lab.garytown.com/$($build)/custom.mft"
#Azure Blob URLS for Content - Used in Payload file. - You wont' have this information until you've setup your BLOB storage
$OSImageURL = "http://hpsr.blob.core.windows.net/public/OSImages/$($build)/Custom.mft"
$AgentURL = "http://hpsr.blob.core.windows.net/public/SRAgent"

$Build = 'Win10' # is is the Version of the Windows WIM I'm going o use for my custom image... I've customized the image using OSDBuilder
$HPProdCode = '83B2'# For if you want to create an image per device... I'm opting to have a single image and run HPIA to install drivers for any model

#Build Basics
#Host Drive Location
$HostRoot = "\\nas\openshare\2Pint"
$SureRecoverRoot = "$HostRoot\SureRecover" #Root location of where you are going to be building things
$SourceMedia = "$SureRecoverRoot\Sources"
$SourceOS = "$SourceMedia\OSImages\$Build"
$SourceAgent = "$SourceMedia\SRAgent" # https://ftp.ext.hp.com/pub/softpaq/sp143001-143500/sp143034.html
#Download: https://ftp.hp.com/pub/softpaq/sp143001-143500/sp143034.exe


#Info about the enviroment you're building the Sure Recover Image / Certs / Manifests / payload files on.
$SureRecoverWorkingpath = "$SureRecoverRoot\HPSRStaging"  #Staging Area
$PayloadFiles = "$SureRecoverRoot\Payloads"
$KeyPath = "$HostRoot\SureRecover\Certificates"  #Location you're keeping your Certs
$ImagePath = "$SureRecoverWorkingpath\OSImages\$Build"  #Location of the Windows Install WIM #Used to split the image with DISM
$AgentPath = "$SureRecoverWorkingpath\SRAgent"

#Set Variables for the certs.
$OpenSLLFilePath = 'C:\Program Files\OpenSSL-Win64\bin\openssl.exe'
$CertPswd = 'P@ssw0rd'
$EndorsementKeyFile = "$KeyPath\Secure Platform Certs-Endorsement Key.pfx"  #Created & downloaded from HP Connect
$SigningKeyFile = "$KeyPath\Secure Platform Certs-Signing Key.pfx"  #Created & downloaded from HP Connect
$CertSubject = "/C=US/ST=MN/L=Glenwood/O=GARYTOWN/OU=IT/CN=lab.garytown.com"
$OSImageCertFile = "$KeyPath\os.pfx"
$AgentImageCertFile = "$KeyPath\re.pfx"
$OpenSSLPath = "C:\Program Files\OpenSSL-Win64\bin"
if (Test-Path -Path $OpenSLLFilePath){
    Set-Location $OpenSSLPath  #Needs to be in this path to allow the openssl to create the certs.
}

Test-Path -Path $EndorsementKeyFile

#Create Folder Structure
if (!(Test-Path -path $HostRoot)){new-item -Path $HostRoot -ItemType Directory -Force | Out-Null}
if (!(Test-Path -path $SureRecoverRoot)){new-item -Path $SureRecoverRoot -ItemType Directory -Force | Out-Null}
if (!(Test-Path -path $SourceMedia)){new-item -Path $SourceMedia -ItemType Directory -Force | Out-Null}
if (!(Test-Path -path $SourceOS)){new-item -Path $SourceOS -ItemType Directory -Force | Out-Null}
if (!(Test-Path -path $SourceAgent)){new-item -Path $SourceAgent -ItemType Directory -Force | Out-Null}
if (!(Test-Path -path $SureRecoverWorkingpath)){new-item -Path $SureRecoverWorkingpath -ItemType Directory -Force | Out-Null}
if (!(Test-Path -path $KeyPath)){new-item -Path $KeyPath -ItemType Directory -Force | Out-Null}
if (!(Test-Path -path $ImagePath)){new-item -Path $ImagePath -ItemType Directory -Force | Out-Null}
if (!(Test-Path -path $AgentPath)){new-item -Path $AgentPath -ItemType Directory -Force | Out-Null}
if (!(Test-Path -path $PayloadFiles)){new-item -Path $PayloadFiles -ItemType Directory -Force | Out-Null}

<# Create Endorsement Key & Signing Key - Update Info First - This was done in HP Connect.  If you don't have HP Connect, you can use this as your template
.\openssl req -x509 -nodes -newkey rsa:2048 -keyout "$KeyPath\kek-key.pem" -out "$KeyPath\kek-cert.pem" -days 3650 -subj "$CertSubject"
.\openssl pkcs12 -inkey "$KeyPath\kek-key.pem" -in "$KeyPath\kek-cert.pem" -export -keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -out "$EndorsementKeyFile" -name "HP Secure Platform Key Endorsement Certificate" -passout "pass:$CertPswd"

.\openssl req -x509 -nodes -newkey rsa:2048 -keyout "$KeyPath\sk-key.pem" -out "$KeyPath\sk-cert.pem" -days 3650 -subj "$CertSubject"
.\openssl pkcs12 -inkey "$KeyPath\sk-key.pem" -in "$KeyPath\sk-cert.pem" -export -keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -out "$SigningKeyFile" -name "HP Secure Platform Signing Key Certificate" -passout "pass:$CertPswd"
#>


#Generate Private & Public PEM Files - Do this Once and don't do it again... just don't lose those files
#Create CA Root Cert
if (!(Test-Path -Path "$KeyPath\ca.key")){ #Only Create Once
    .\openssl req -sha256 -nodes -x509 -newkey rsa:2048 -keyout "$KeyPath\ca.key" -out "$KeyPath\ca.crt" -subj "$CertSubject"
}
#OS
if (!(Test-Path -Path "$KeyPath\os.key")){  #Only Create Once
    .\openssl req -sha256 -nodes -newkey rsa:2048 -keyout "$KeyPath\os.key" -out "$KeyPath\os.csr" -subj "$CertSubject"
    .\openssl x509 -req -sha256 -in "$KeyPath\os.csr" -CA "$KeyPath\ca.crt" -CAkey "$KeyPath\ca.key" -CAcreateserial -out "$KeyPath\os.crt"
    .\openssl pkcs12 -inkey "$KeyPath\os.key" -in "$KeyPath\os.crt" -export -out "$KeyPath\os.pfx"  -CSP "Microsoft Enhanced RSA and AES Cryptographic Provider" -passout "pass:$CertPswd"
}
#RE
if (!(Test-Path -Path "$KeyPath\re.key")){ #Only Create Once
    .\openssl req -sha256 -nodes -newkey rsa:2048 -keyout "$KeyPath\re.key" -out "$KeyPath\re.csr" -subj "$CertSubject"
    .\openssl x509 -req -sha256 -in "$KeyPath\re.csr" -CA "$KeyPath\ca.crt" -CAkey "$KeyPath\ca.key" -CAcreateserial -out "$KeyPath\re.crt"
    .\openssl pkcs12 -inkey "$KeyPath\re.key" -in "$KeyPath\re.crt" -export -out "$KeyPath\re.pfx"  -CSP "Microsoft Enhanced RSA and AES Cryptographic Provider" -passout "pass:$CertPswd"
}


#Default Public Key that came with SR Agent... not actually using for this solution.
#$AgentPublicKeyFile  = "$KeyPath\hpsr_agent_public_key.pem" #Default Signing Key for Default Agent


#region Custom Image
#Create the Custom Image

#Split the WIM File (per docs recommendations)
dism /Split-Image /ImageFile:"$($SourceOS)\install.wim" /SwmFile:"$($ImagePath)\$($Build).swm" /FileSize:64

#Building OS Manifest File:
$mftFilename = "Custom.mft"
$sigFileName = "Custom.sig"
Remove-Item -Path "$ImagePath\$mftFilename" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$ImagePath\$sigFilename" -Force -ErrorAction SilentlyContinue
$imageVersion = '22.12.02'
$header = "mft_version=1, image_version=$imageVersion"
Out-File -Encoding UTF8 -FilePath $SureRecoverWorkingpath\$mftFilename -InputObject $header
$Files = Get-ChildItem -Path $ImagePath -Recurse | Where-Object {$_.Attributes -ne 'Directory'}
$ToNatural = { [regex]::Replace($_, '\d*\....$',{ $args[0].Value.PadLeft(50) }) }
$pathToManifest = $ImagePath
$total = $Files.count
$current = 1
$Files | Sort-Object $ToNatural | ForEach-Object {
     Write-Progress -Activity "Generating manifest" -Status "$current of $total ($_)" -PercentComplete ($current / $total * 100)
     $hashObject = Get-FileHash -Algorithm SHA256 -Path $_.FullName
     $fileHash = $hashObject.Hash.ToLower()
     $filePath = $hashObject.Path.Replace($pathToManifest + '\', '')
     $fileSize = (Get-Item $_.FullName).length
     $manifestContent = "$fileHash $filePath $fileSize"
     Out-File -Encoding utf8 -FilePath $SureRecoverWorkingpath\$mftFilename -InputObject $manifestContent -Append
     $current = $current + 1
}
$content = Get-Content $SureRecoverWorkingpath\$mftFilename
$encoding = New-Object System.Text.UTF8Encoding $False
[System.IO.File]::WriteAllLines($pathToManifest + '\' + $mftFilename, $content, $encoding)


#Sign Image Manfiest Files
.\openssl dgst -sha256 -sign $OSImageCertFile -passin pass:$CertPswd -out "$ImagePath\$sigFilename" "$ImagePath\$mftFilename" 

#endregion

#Copy to Production WebServer Folder: - Do Manually for Azure Cloud Blob Storage
#copy-item $ImagePath\* -Destination $ProdWebServerImagePath -Force -Verbose

#region Agent

#AGENT:
#Building Agent Manifest File:
$mftFilename = "recovery.mft"
$sigFileName = "recovery.sig"
Remove-Item -Path "$AgentPath\$mftFilename" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$AgentPath\$sigFilename" -Force -ErrorAction SilentlyContinue
$imageVersion = '20'
$header = "mft_version=20, image_version=$imageVersion"
Out-File -Encoding UTF8 -FilePath $SureRecoverWorkingpath\$mftFilename -InputObject $header
$Files = Get-ChildItem -Path $AgentPath -Recurse | Where-Object {$_.Attributes -ne 'Directory'}
$ToNatural = { [regex]::Replace($_, '\d*\....$',{ $args[0].Value.PadLeft(50) }) }
$pathToManifest = $AgentPath
$total = $Files.count
$current = 1
$Files | Sort-Object $ToNatural | ForEach-Object {
     Write-Progress -Activity "Generating manifest" -Status "$current of $total ($_)" -PercentComplete ($current / $total * 100)
     $hashObject = Get-FileHash -Algorithm SHA256 -Path $_.FullName
     $fileHash = $hashObject.Hash.ToLower()
     $filePath = $hashObject.Path.Replace($pathToManifest + '\', '')
     $fileSize = (Get-Item $_.FullName).length
     $manifestContent = "$fileHash $filePath $fileSize"
     Out-File -Encoding utf8 -FilePath $SureRecoverWorkingpath\$mftFilename -InputObject $manifestContent -Append
     $current = $current + 1
}
$content = Get-Content $SureRecoverWorkingpath\$mftFilename
$encoding = New-Object System.Text.UTF8Encoding $False
[System.IO.File]::WriteAllLines($pathToManifest + '\' + $mftFilename, 
$content, $encoding)


# You can sign the agent manifest with this command
.\openssl dgst -sha256 -sign $AgentImageCertFile -passin pass:$CertPswd -out "$AgentPath\$sigFilename" "$AgentPath\$mftFilename" 

#endregion

#Increment this number each time you make a change to the Payload file (like change the URL).  It does NOT need to be changed if you update an image or agent media.  Only if you change certificates or URLs.
[int16]$Version = 8

#Create the HP Secure Platform Payload Files - Provisining Secure Platform - Endorsement & Signing Payloads
New-HPSecurePlatformEndorsementKeyProvisioningPayload -EndorsementKeyFile $EndorsementKeyFile -EndorsementKeyPassword $CertPswd -OutputFile "$PayloadFiles\SPEndorsementKeyPP.dat"
New-HPSecurePlatformSigningKeyProvisioningPayload -EndorsementKeyFile $EndorsementKeyFile -EndorsementKeyPassword $CertPswd -SigningKeyFile $SigningKeyFile -SigningKeyPassword $CertPswd  -OutputFile "$PayloadFiles\SPSigningKeyPP.dat"

#Build the OSPayload file for Sure Recover Custom OS URL
New-HPSureRecoverImageConfigurationPayload -Image OS -SigningKeyFile $SigningKeyFile -SigningKeyPassword $CertPswd -ImageCertificateFile $OSImageCertFile -ImageCertificatePassword $CertPswd -Url $OSImageURL -Version $Version  -OutputFile "$PayloadFiles\OSImagePayload.dat" -Verbose

#AgentFile - Only needed if hosting your own Agent (which is optional)
New-HPSureRecoverImageConfigurationPayload -Image agent -SigningKeyFile $SigningKeyFile -SigningKeyPassword $CertPswd -ImageCertificateFile $AgentImageCertFile -ImageCertificatePassword $CertPswd -Url $AgentURL -Version $Version  -OutputFile "$PayloadFiles\AgentPayload.dat" -Verbose


#Create Deprovisioning Payloads - For when you want to change your Sure Recover Settings, you need to deprovision first (or at least I've had to in my test machine)
New-HPSureRecoverDeprovisionPayload -SigningKeyFile $SigningKeyFile -SigningKeyPassword $CertPswd -OutputFile "$PayloadFiles\SureRecoverDeprovision.dat"
New-HPSecurePlatformDeprovisioningPayload -Verbose -EndorsementKeyFile $EndorsementKeyFile -EndorsementKeyPassword $CertPswd -OutputFile "$PayloadFiles\SecurePlatformDeprovision.dat"


Set-HPSecurePlatformPayload -PayloadFile "$PayloadFiles\SPEndorsementKeyPP.dat"
Set-HPSecurePlatformPayload -PayloadFile "$PayloadFiles\SPSigningKeyPP.dat"
