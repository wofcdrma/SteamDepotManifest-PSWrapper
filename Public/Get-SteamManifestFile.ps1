Function Get-SteamManifestFile {

    [CmdletBinding()]
    [OutputType([Object])]

    Param (

        [Parameter(Mandatory = $true)]
        [String]
        $DepotID,

        [Parameter(Mandatory = $false)] # could expand this to support an array of manifests to input, but use-cases would be very niche - download all option should be better
        $ManifestID,

        [Parameter(HelpMessage = 'Use this parameter to override what code is used to download the manifest file & avoid using gmrc. Do not use this if you do not have a Manifest Request Code.', Mandatory = $false)]
        $MRCode,

        [Parameter(HelpMessage = 'This switch disables appending the SeenDate to the manifest filename. This is assuming you allow this script to parse the SteamDB manifest table. Set this to $true if you want to enable this setting. Default option is false.', Mandatory = $false)]
        [Switch]
        $DoNotAppendSeenDate
        
    )

    Begin {

        If (-not(Test-Path -Path "$env:SteamDepotPath\$DepotID")) { New-Item -Path "$env:SteamDepotPath\$DepotID" -ItemType Directory -Force | Out-Null }

        $manifestReqHeaders = @{
            "Host" = "cache11-ord1.steamcontent.com"
            "Accept" = "text/html,*/*;q=0.9"
            "accept-charset" = "ISO-8859-1,utf-8,*;q=0.7"
            "user-agent" = "Valve/Steam HTTP Client 1.0"
            "Accept-Encoding" = "identity"
        }

        If ($null -eq $ManifestID) {

            $MRCode = $null # null this, as the manifest ID and MRCode is meant to be provided at the same time. You shouldn't be in a situation where you have a MRCode and no Manifest ID.

            Write-Host "`n`nThe ManifestID input variable is empty." -ForegroundColor Yellow
            Write-Host "Please select what you would like to do:"
            Write-Host "[1]. Manually input single Manifest ID."
            Write-Host "[2]. Get all available Manifest IDs (parse clipboard from SteamDB manifest table values)"
            Write-Host "[3]. Cancel`n`n"
            $MIDChoice = Read-Host "Input your choice"

            switch ($MIDChoice) {
                "1" {
                    Write-Host "`n"
                    $ManifestID = Read-Host "Please input your SINGLE Manifest ID of Depot: $DepotID you'd like to download."
                }
                "2" {
                    $ManifestIDTable = ConvertFrom-SteamDBManifestList -DepotID $DepotID
                    Write-Host "Parsed the following Manifest IDs:"
                    $ManifestIDTable | Format-Table | Out-Host
                }
                "3" {
                    throw "Cancelling."
                }
                default {
                    throw "ManifestID choice selection did not match the requested format."
                }
            }

        }


        If ($null -eq $MRCode) {

            If ($ManifestID -is [String]) {

                $MRCode = Get-ManifestRequestCode -ManifestID $ManifestID

                If ($MRCode) {
                    $ManifestReqList = @()
                    $ManifestReqList += [PSCustomObject]@{
                        DepotID    = $DepotID
                        ManifestID = $ManifestID
                        MRCode     = $MRCode
                    }
                }

            } else {
                If ($ManifestIDTable) {
                    
                    $ManifestReqList = @()

                    $ManifestIDTable | ForEach-Object {
                    
                        $MRCode = $null
                        $MRCode = Get-ManifestRequestCode -ManifestID $_.ManifestID
                        
                        If ($MRCode) {
                            $ManifestReqList += [PSCustomObject]@{
                                DepotID    = $_.DepotID
                                SeenDate   = $_.SeenDate
                                ManifestID = $_.ManifestID
                                MRCode     = $MRCode
                            }
                       } else {
                            Write-Host "Error fetching MRCode from gmrc for Manifest ID: $($_.ManifestID)" -ForegroundColor Red
                            throw "Error fetching MRCode from gmrc for Manifest ID"
                       }

                    }

                } else {
                    throw "unexpected format for ManifestID variable/object"
                }
            }

        }

    }


    Process {
        
        Write-Host "Entering the process block with the following Manifest File Request List:"
        $ManifestReqList | Format-Table | Out-Host

        $results = @()

        $ManifestReqList | ForEach-Object {

            $tempDir          = $null
            $manifestReq      = $null
            $manifestSavePath = $null

            If ($($_.DepotID) -and $($_.ManifestID) -and $($_.MRCode)) {
            
                $tempDir = "$($env:TEMP)\$(New-Guid)"
                New-Item -ItemType Directory -Path $tempDir | Out-Null

                If ($_.SeenDate -and $DoNotAppendSeenDate -eq $false) {
                    $manifestSavePath = "$env:SteamDepotPath\$($_.DepotID)\$($_.DepotID)_$($_.SeenDate)_$($_.ManifestID).manifest"
                } else {
                    $manifestSavePath = "$env:SteamDepotPath\$($_.DepotID)\$($_.DepotID)_$($_.ManifestID).manifest"
                }
                
                try {
                    # this doesn't work -- I need to decompress the file that is downloaded. probably make it output to a temp file, uncompress, then set-content to manifestsavepath
                    Write-Host "Requesting manifest file from Steam CDN." -ForegroundColor DarkGray # debug
                    $manifestReq = Invoke-WebRequest -Method GET -Headers $manifestReqHeaders -Uri "https://cache11-ord1.steamcontent.com/depot/$($_.DepotID)/manifest/$($_.ManifestID)/5/$($_.MRCode)" -HttpVersion 1.1 -OutFile "$($tempDir)\raw" -PassThru
                    Write-Host "HTTP request complete. Status: $($manifestReq.StatusCode)" -ForegroundColor DarkGray # debug
                } catch {
                    Write-Host "Error saving the manifest file: $_" -ForegroundColor Red
                    Pause
                }
                


                If ($manifestReq.StatusCode -eq '200') {

                    Expand-Archive -LiteralPath "$($tempDir)\raw" -DestinationPath $($tempDir)

                    $extractedFile = (Get-ChildItem -LiteralPath $($tempDir) -Exclude "raw").FullName

                    If ($extractedFile.Count -eq '1') {

                        try {
                            Move-Item -Path $extractedFile -Destination $manifestSavePath -ErrorAction Stop
                            Write-Host "Saved manifest file to $manifestSavePath.`n`n" -ForegroundColor Green
                            $results += [PSCustomObject]@{
                                DepotID          = $($_.DepotID)
                                ManifestID       = $($_.ManifestID)
                                ManifestSavePath = $($manifestSavePath)
                            }
                        } catch {
                            Write-Host "Error saving the temporarily extracted manifest file. Error: $_." -ForegroundColor Yellow
                            Pause
                        }

                    } else {
                        Write-Host "Manifest archive from Steam CDN contained multiple files. Expected 1 file." -ForegroundColor Yellow
                        Pause
                    }

                } else {
                    Write-Host "manifest request code is present, but steam cdn did not return a 200 status to pull the manifest file`n" -ForegroundColor Red
                    Write-Host "DepotID - $($_.DepotID)"
                    Write-Host "ManifestID - $($_.ManifestID)"
                    Write-Host "MRCode - $($_.MRCode)"
                    Pause
                    # Write-Host "DepotDecryptionKey - $DepotDecryptionKey" --- I'll likely seperate the DDK stuff from this function. Not sure if I will ever link these two together in one function.
                    # In my mind, a proper use would be one script using this function, a seperate get-ddk function, then making a DDM command to combine the two results.
                }

                Remove-Item -Path $tempDir -Recurse -Force

            } else {
                throw "DepotID / ManifestID / MRCode in the ManifestReqList object not present. Can't make the request to Steam CDN to pull the manifest file."
            }

        }
        
        $resultsJson = $results | ConvertTo-Json -Depth 10

        Write-Output $resultsJson

    }

}