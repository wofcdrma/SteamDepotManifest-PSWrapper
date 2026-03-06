# Note: The use of depotkeys.json in this module is currently unused. I'll potentially expand this module to work with DepotDownloaderMod. I'm undecided how I'll implement.
Function Get-DepotKeysJson {

    [CmdletBinding()]

    Param ()

    Process {

        $depotkeysPath = "$env:SteamDepotRoot\depotkeys.json"

        If (-not(Test-Path -Path "$depotkeysPath")) {
            Write-Host "depotkeys.json not found -- downloading them to $depotkeysPath" -ForegroundColor Yellow
            try {
            Invoke-WebRequest -OutFile "$depotkeysPath" -Uri "https://raw.githubusercontent.com/SteamAutoCracks/ManifestHub/refs/heads/main/depotkeys.json"
            Write-Host "Downloaded depotkeys.json to $depotkeysPath`n`n" -ForegroundColor Green
            } catch {
                Write-Host "Error grabbing the depotkeys.json: $_"
                Pause
            }
        }
        
    }

}