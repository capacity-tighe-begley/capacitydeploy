# Safeguard Hold Database - Community Ed

I've built this database for my own use, but have published the data as well as the method I used to build it.  Thanks Adam Gross for laying the foundation:
Based on https://github.com/AdamGrossTX/FU.WhyAmIBlocked/blob/master/Get-SafeguardHoldInfo.ps1 


Database Safeguard Hold ID Count: 115 | 2024.03.04

## Getting Required Data for Building Database
Basically I ran this in my environment:

### CMPIVOT Query

``` powershell
<#
Registry('HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\TargetVersionUpgradeExperienceIndicators\*') | where Property == 'GatedBlockId' and Value != '' and Value != 'None'
| join kind=inner (
		Registry('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OneSettings\compat\appraiser\*') 
		| where Property == 'ALTERNATEDATALINK')
| join kind=inner (
		Registry('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OneSettings\compat\appraiser\*') 
		| where Property == 'ALTERNATEDATAVERSION')
| project Device,GatedBlockID=Value,ALTERNATEDATALINK=Value1,ALTERNATEDATAVERSION=Value2
#>
```

[![CMPivot](media/CMPivot.png)](media/CMPivot.png)

### Excel Cleanup

I'll copy the URLs (ALTERNATEDATALINK) & Versions (ALTERNATEDATAVERSION) into Excel, Sort & Remove Duplicates:

[![RemoveDups1](media/RemoveDups.png)](media/RemoveDups.png)
[![RemoveDups2](media/RemoveDups2.png)](media/RemoveDups2.png)
[![RemoveDups3](media/RemoveDups3.png)](media/RemoveDups3.png)

### Compare with Current List of URLS / Versions

Then Compare with the [build script](https://github.com/gwblok/garytown/blob/master/Feature-Updates/SafeGuardHolds/Get-SafeGuardHoldData.ps1).

[![BuildScript](media/BuildScript.png)](media/BuildScript.png)


### Send me any additional items you have or do a Pull Request

If you find URLs and Versions which I do not have listed, please send them to me (@gwblok on Twitter), and I'll add those and rebuild the database with anything additional that gets added.


The database is a JSON file for easy ingestion.  I have a PowerShell Sample script you can use as a template to look up the Safeguard Hold IDs easier.

## If you would like to run the script yourself for fun....

Running the Script can take awhile as it has to export the SDB files into XML.  It only has to do this once per Version, so if you've run the script before and export to XML, if it finds the coorisponding XML, it will move to the next one

[![RunScript1](media/RunScript1.png)](media/RunScript1.png)
[![RunScript2](media/RunScript2.png)](media/RunScript2.png)


Hit me up on Twitter with any questions.
