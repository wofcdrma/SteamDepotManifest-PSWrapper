# SteamDepotManifest-PSWrapper

This is a PowerShell wrapper to download and save Steam Depot manifest file(s) **directly from Steam CDN**, optionally in bulk.
<br>
<br>
You may find this useful if you:
- Don't want to rely on third-party services relaying manifest files.
- Don't want only the latest manifest (as most third-party services give you the latest by default).
- Are looking to download all historical manifest files available from a depot in bulk and feed them into an automated process.
<br>


**Notes:**

As set in the main module file, the default save location for the depots is: C:\SteamDepot\depots\. If you want to change this, you can do so by editing the enviornment variables in the module file.
<br>
<br>
I might expand this module to include functions to download manifest(s) & fetch Depot Decryption Keys, but this can already be done with little effort in a small script using [DepotDownloaderMod](https://github.com/SteamAutoCracks/DepotDownloaderMod) and [depotkeys.json](https://github.com/SteamAutoCracks/ManifestHub/blob/main/depotkeys.json).
<br>
<br>
This does send a GET request to gmrc.wudrm.com with the requested manifest ID(s) to generate the Manifest Request Code (MRC), which is used to invoke the manifest file download from Steam CDN. SteamTools uses this same service to get valid MRCs.

## Usage
First, you will need to import the module. (Set-Location to the module's location):
```
Import-Module -Name .\SteamDepotManifest-PSWrapper.psm1
```
<br>

**I recommend assigning the public functions to output directly to a variable, as they return JSON.**
<br>
### Get-SteamManifestFile
Syntax:
```
Get-SteamManifestFile [-DepotID] <string> [[-ManifestID] <string>] [[-MRCode] <string>] [-DoNotAppendSeenDate] [<CommonParameters>]
```
**Note:** This function will only save the SeenDate in the manifest filename if it parses it from the SteamDB manifest table.
<br>
<br>

You can find DepotIDs and ManifestIDs on [SteamDB](https://steamdb.info/), or by using the Steam Console, if you are familiar.
<br>
<br>

To download a manifest file, specify a Depot ID and a Manifest ID:
```
$Result = Get-SteamManifestFile -DepotID "239031" -ManifestID "8341915722048998803"
```
Once the download is complete, the manifest file will be saved into the DepotID's folder:
```
PS C:\SteamDepot\depots\239031> gci

    Directory: C:\SteamDepot\depots\239031

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a---            3/5/2026  8:00 PM          64462 239031_8341915722048998803.manifest
```
<br>
<br>

To have the function help parse all Manifest IDs for a depot and download all manifest files, leave the ManifestID parameter blank. This will also save the manifest files with the SeenDate appended to them:
```
$Result = Get-SteamManifestFile -DepotID "239031" 
```
There's a private function (ConvertFrom-SteamDBManifestList) which will ask you to copy the manifest table values from SteamDB, and the script will call Get-Clipboard and parse the data out using the tabulation character as a delimiter. Thereafter, the depot folder structure will look like this once all manifest files are downloaded:
```
PS C:\SteamDepot\depots\239031> gci

    Directory: C:\SteamDepot\depots\239031

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a---            3/5/2026  8:00 PM          64568 239031_2013-08-08T170858Z_2819895400919775656.manifest
-a---            3/5/2026  8:00 PM          64479 239031_2013-08-10T230355Z_2108374104770279408.manifest
-a---            3/5/2026  8:00 PM          64462 239031_2013-08-11T154452Z_8341915722048998803.manifest
-a---            3/5/2026  8:00 PM          68898 239031_2013-08-12T031000Z_7516800706811144030.manifest
-a---            3/5/2026  8:00 PM          64573 239031_2013-08-12T181742Z_1596981945034753629.manifest
```
<br>
<br>




If you do not want the SeenDate appended to the manifest filename, you can set the DoNotAppendSeenDate switch to $true. Example:
```
$Result = Get-SteamManifestFile -DepotID "239031" -DoNotAppendSeenDate $true
```
<br>
<br>

Get-SteamManifestFile JSON output format (example):
```
[
  {
    "DepotID": "292631",
    "ManifestID": "579737333388101563",
    "ManifestSavePath": "C:\\SteamDepot\\depots\\292631\\292631_2014-09-17T232347Z_579737333388101563.manifest"
  },
  {
    "DepotID": "292631",
    "ManifestID": "1050384281662285021",
    "ManifestSavePath": "C:\\SteamDepot\\depots\\292631\\292631_2014-09-12T220531Z_1050384281662285021.manifest"
  }
]
```

The intention of this JSON output is to make it easy to feed into other tools like DepotDownloadMod if you wish to.
