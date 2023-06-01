<#
.SYNOPSIS
    Show Lisk-Service Public API Endpoint(s) Status

.PARAMETER Net
    Beta, Test, Main

.EXAMPLE
    .\Show-LiskServiceStatus.ps1 -Net Beta

.NOTES
    Author     : Gr33nDrag0n

.LINK
    Lisk-Core CLI Documentation
        https://lisk.com/documentation/lisk-core/v4/core-cli.html

    Lisk-Core API Documentation
        https://lisk.com/documentation/beta/api/lisk-node-rpc.html

    Lisk Service API Documentation
        https://github.com/LiskHQ/lisk-service/blob/v0.7.0-beta.1/docs/api/version3.md
#>

#Requires -Version 7.0

[CmdletBinding()]
Param(
    [parameter(Mandatory = $False)]
    #[ValidateSet('Main', 'Test', 'Beta')]
    [ValidateSet('Beta')]
    [System.String] $Net = 'Beta'
)

#======================================================================================================================
# Configuration

$BetaConfigFile = "$PSScriptRoot\JSON\lwd4-config.beta.json"

# Timeout in second(s) for Invoke-RestMethod
$TimeoutSec = 1

#======================================================================================================================
# Load Configuration

switch ( $NET ) {

    'Beta' {

        # TODO: Test-Path

        $Config = Get-Content -Path $BetaConfigFile -Raw | ConvertFrom-Json
        break
    }

}

#======================================================================================================================
# MAIN

$ErrorMessage = ''

################################################################################
## Build TopHeight

$TopHeight = $NULL

$Network_ConnectedPeers = Invoke-RestMethod -Uri $Config.DefaultCoreAPI -Method GET -Body $( @{
        jsonrpc = '2.0'
        id      = '1'
        method  = 'network_getConnectedPeers'
        params  = @{}
    } | ConvertTo-Json -Depth 100 -Compress )

if ( $NULL -ne $Network_ConnectedPeers ) {

    $TopHeight = $Network_ConnectedPeers.result.Options.Height | Sort-Object -Unique -Descending | Select-Object -First 1
}

################################################################################
## Show Header

Clear-Host

Write-Host 'LiskWatchDog 4 by ' -ForegroundColor White -NoNewline
Write-Host 'gr33ndrag0n' -ForegroundColor Green
Write-Host ''

Write-Host 'Network Name : ' -ForegroundColor Cyan -NoNewline
Write-Host $Config.NetworkName -ForegroundColor White -NoNewline
Write-Host '     Network TopHeight : ' -ForegroundColor Cyan -NoNewline
Write-Host $TopHeight -ForegroundColor White
Write-Host ''

################################################################################
## Show ApiStatusList

ForEach ( $PublicServiceNode in $Config.PublicServiceNode ) {

    Write-Host "# $($PublicServiceNode.Name)`r`n" -ForegroundColor Cyan

    $ApiStatus = $NULL

    try {
        $ApiStatus = Invoke-RestMethod -Uri "$($PublicServiceNode.URL)api/status" -Method GET -TimeoutSec $TimeoutSec
    } catch {
        $ErrorMessage += "Connection to '$($PublicServiceNode.URL)api/status' timeout.`r`n"
    }

    if ( $NULL -ne $ApiStatus ) {

        Write-Host 'API Status' -ForegroundColor White
        $ApiStatus | Format-List *

        #---

        $ApiReady = $NULL

        try {
            $ApiReady = Invoke-RestMethod -Uri "$($PublicServiceNode.URL)api/ready" -Method GET -TimeoutSec $TimeoutSec
        } catch {
            $ErrorMessage += "Connection to '$($PublicServiceNode.URL)api/ready' timeout.`r`n"
        }

        if ( $NULL -ne $ApiReady ) {

            Write-Host 'API Ready' -ForegroundColor White
            $ApiReady.services | Format-List *
        }

    }
}


################################################################################
## Show Error

if ( $ErrorMessage -ne '' ) {
    Write-Host "`r`n$ErrorMessage" -ForegroundColor Red
}
