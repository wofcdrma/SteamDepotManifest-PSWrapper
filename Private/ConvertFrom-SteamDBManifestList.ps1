Function ConvertFrom-SteamDBManifestList {

    [CmdletBinding()]
    [OutputType([Object])]

    Param (

        [Parameter(Mandatory = $true)]
        [String]
        $DepotID

    )

    Process {

        Clear-Host # might remove later
        
        Write-Host "SteamDB doesn't provide a public API for grabbing the historical manifest file IDs, and they forbid scraping."
        Write-Host "Steam Web API does not provide historical manifest IDs either, they only provide the latest manifest ID.`n"
        Write-Host "This function parses your clipboard using the tabulation character as a delimiter.`n"
        Write-Host "Open this SteamDB link (and optionally sign into your steam account to see all manifests listed in SteamDB):"
        Write-Host "https://steamdb.info/depot/$DepotID/manifests/`n`n" -ForegroundColor DarkBlue
        Write-Host "Select all manifest table values. Click and drag from the whitespace of the first 'Seen Date' value to the last 'ManifestID' value.`nDo not include the table headers.`nExample:PLACEHOLDER`n`n"
        Write-Host "Continue when you have the table values in your clipboard."
        Pause

        $ParsedManifestList = Get-Clipboard | 
            ConvertFrom-Csv -Delimiter "`t" -Header "SeenDate", "RelativeDate", "RawManifestID" | 
            Select-Object @{ Name = 'DepotID'; Expression = { $DepotID } },
                        @{
                            Name = 'SeenDate';
                            Expression = { ([datetime]($_.SeenDate -replace ' –', '' -replace ' UTC', '')).ToString("yyyy-MM-ddTHHmmss\Z") }
                        },
                        RelativeDate,
                        @{ Name = 'ManifestID'; Expression = { $_.RawManifestID -replace '\s+.*', '' } },
                        @{ Name = 'Notes'; Expression = { $_.RawManifestID -replace '^\d+\s*', '' } }

        # could try catch here if the table doesn't have correct values

        Clear-Host # might remove later

        Write-Output -InputObject $ParsedManifestList
    
    }

}