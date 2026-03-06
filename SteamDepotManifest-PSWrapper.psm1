# Write-Host -ForegroundColor DarkGray "[INFO] Module root directory is: $PSScriptRoot"


#region ProviderPath

$paths = @(
    'Private',
    'Public'
)


ForEach ($path in $paths) {
    (Get-ChildItem -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath $path) -Filter '*.ps1') | ForEach-Object {
        if ($_.FullName) { . $_.FullName }
    }
}

#endregion ProviderPath


#region StaticVariables

$env:SteamDepotRoot = "C:\SteamDepot"
$env:SteamDepotPath = "C:\SteamDepot\depots"

If (-not(Test-Path -Path "$env:SteamDepotRoot")) { New-Item -Path "$env:SteamDepotRoot" -ItemType Directory -Force | Out-Null }
If (-not(Test-Path -Path "$env:SteamDepotPath")) { New-Item -Path "$env:SteamDepotPath" -ItemType Directory -Force | Out-Null }

Get-DepotKeysJson

#endregion StaticVariables


<# notes/thoughts

# seems impossible to obtain a list of all historical manifest IDs from a specified depot without using SteamDB, or owning a legitimate copy of the game on your steam account.
# DDM has a -manifest-only option to do this, but can only grab the latest public ManifestID unless you are signed in and own the game (presumably).
# my original vision for this script was: 
# enter depot ID -> script returns list of all manifest IDs -> user selects manifest file(s) to download -> script pulls manifests from steam cdn -> script pulls ddk keys and puts them next to manifests -> now ready to download manifest with DDM
# SteamDB doesn't have a public API and they forbid scraping :|
# when you request the manifest lists using SteamDBs web app (GET, https://steamdb.info/depot/DEPOTID/manifests/), clearly there's:
# a steamdb specific cookie (which probably links to your Steam account, and is likely temporary) that (presumably) gives you access to view the manifest table
# cloudflare turnstile
# required javascript code to run
# Cloudflare WAF
# possibly CF API Shield, but I doubt this would really interfere.
# SteamDB is extremely cringe for doing this
#
# maybe copy pasting the table from the steamdb webapp data would be the easiest. scraping is def possible, but too much effort. yeah I think I'll do this.



# create function to create ddk file - parse the manifesthub ddk json, then save it to a file in the depot folder? How to handle missing keys? what is Victor using in Piracy Lords? the depotkeys.json file is currently 3 months old. how often does it get updated?
# my idea right now would be:
# C:\SteamDepot\depots\DepotID\
# C:\SteamDepot\depots\DepotID\key.ddk
# C:\SteamDepot\depots\DepotID\1234567890.manifest
# C:\SteamDepot\depots\DepotID\1234567891.manifest
# C:\SteamDepot\depots\DepotID\1234567892.manifest -- save (optinally all) manifest files received to disk.
# C:\SteamDepot\depots\DepotID\1234567890\[gamedata] -- or whichever manifest(s) you want to download
# possibly something with more user-friendly path names, but still informative


# another idea:
# utilize VPN with dynamic tunneling by specified DNS names for gmrc HTTP request or any other scraping to prevent IP bans and better privacy. could also tunnel steam cdn if you didn't want your IP downloading the manifest chunks, but obv slower.

#>