Function Get-ManifestRequestCode {

    [CmdletBinding()]
    [OutputType([String])]

    Param (

        [Parameter(HelpMessage = 'Manifest ID of which you are requesting the MRCode to download the manifest file with.', Mandatory = $true)]
        [String]
        $ManifestID
        
    )

    Process {

        $gmrcHeaders = @{
            "Host" = "gmrc.wudrm.com"
            "Accept" = "*/*"
            "Referer" = "http://gmrc.wudrm.com"
        }

        Write-Host "Requesting manifest request code from gmrc." -ForegroundColor DarkGray # debug
        $MRCodeReq = Invoke-WebRequest -Method GET -Headers $gmrcHeaders -Uri "http://gmrc.wudrm.com/manifest/$ManifestID" -HttpVersion 1.1
        Write-Host "HTTP request complete. Status: $($MRCodeReq.StatusCode)" -ForegroundColor DarkGray # debug

        If ($MRCodeReq.StatusCode -eq '200') {
            $MRCode = $MRCodeReq.Content
        } else {
            $MRCode = $null
            throw "gmrc.wudrm.com was unable to get a manifest request code for $ManifestID."
        }

        Write-Output -InputObject $MRCode
        
    }

}