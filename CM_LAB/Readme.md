# ConfigMgr Personal Lab files

These are scripts and files I use in my own personal lab, stored here for whenever I need, or for others to borrow

## Installers - Install before CM - Probably after SQL is installed

.Net 4.8.1

https://learn.microsoft.com/en-us/dotnet/framework/install/on-server-2022

C++  (x86 + x64) to upgrade the ones that SQL or something else put there.

https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist?view=msvc-170


## Links
Because I always forget where I got things from, so now on my 4th or 5th time, I'm just documnenting it here.

Guide:

https://www.recastsoftware.com/resources/building-a-configmgr-lab-from-scratch/

Cert Setup (after using the guide above to setup DC & PKI): 

Watch Justin's YouTube Video https://www.youtube.com/watch?v=nChKKM9APAQ

SQL SPN Kerberos Tool: Use this after you install SQL, before you install ConfigMgr

https://www.microsoft.com/en-US/download/details.aspx?id=39046


## Things I often forget
Add SYSTEM to SRC Share with full rights, otherwise issues with BootMedia (and other things)

If anything goes wrong with modifing a WIM or adding Boot Media, etc... it's probably the source share permissions

## Post Setup
Edit a couple .NET config files if you're not installing CM to C:\ 

https://www.prajwaldesai.com/fatal-msi-error-bgbisapi-msi-could-not-be-installed/

