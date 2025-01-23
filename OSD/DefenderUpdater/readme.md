# Windows Defender Package Update Automation

Based on Johan's Script & [Jorgen's Blog](https://ccmexec.com/2016/01/download-and-deploy-windows-defender-definitions-for-windows-10-during-osd/)

Includes Scheduled Task that runs daily & Script that updates a package.

To use:
- Decide where you want to store the script.
- Update the XML for the Scheduled task to where you store the script
- Import the Scheduled Task, leverage a gSMA account or other service account with permissions to both CM & the Package Location
- Account with access to file share & CM
- Scheduled task runs on machine with CM Console (So it has access to the PS Commandlets)
  - These requirements are NOT the same as Johan's script which doesn't leverage the CM PS Commandlets 

Once you have this setup, you can add steps to your Task Sequence to leverage the updated Defender Defs.  Look to Jorgen's blog in the link above for more details about integration. 

## Scheduled Task:
```
In my lab, I'm just using a user account, but in Production, I'm using a gSMA account.
```

[![Defender Updater 01](DefenderUpdate01.png)](DefenderUpdate01.png)

## Log File:

[![Defender Updater 02](DefenderUpdate02.png)](DefenderUpdate02.png)

## Package in Console:

[![Defender Updater 03](DefenderUpdate03.png)](DefenderUpdate03.png)
