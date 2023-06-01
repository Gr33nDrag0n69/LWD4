<#
.SYNOPSIS
    Show Generator Last Block

.PARAMETER Net
    Beta, Test, Main

.EXAMPLE
    .\Show-GeneratorLastBlock.ps1 -Net Beta

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
## Build GeneratorStatusList

$GeneratorStatusList = @()

ForEach ( $PrivateCoreNode in $Config.PrivateCoreNode ) {

    $GeneratorStatus = $NULL

    try {
        $GeneratorStatus = Invoke-RestMethod -Uri $PrivateCoreNode.URL -Method GET -TimeoutSec $TimeoutSec -Body $( @{
                jsonrpc = '2.0'
                id      = '1'
                method  = 'generator_getStatus'
                params  = @{}
            } | ConvertTo-Json -Depth 100 -Compress )
    } catch {
        $ErrorMessage += "Connection to '$($PrivateCoreNode.URL))' timeout.`r`n"
    }

    if ( $NULL -ne $GeneratorStatus ) {

        $GeneratorStatus = $GeneratorStatus.result.status

        ForEach ( $Item in $GeneratorStatus ) {

            $Address = $Item | Select-Object -ExpandProperty address

            $ValidatorName = $Config.Validator | Where-Object { $_.Address -eq $Address } | Select-Object -ExpandProperty Name

            $GeneratorStatusList += [PSCustomObject]@{

                NodeName           = $PrivateCoreNode.Name
                #URL                = $PrivateCoreNode.URL
                ValidatorName      = $ValidatorName
                Address            = $Address
                Height             = $Item.height
                MaxHeightPrevoted  = $Item.maxHeightPrevoted
                MaxHeightGenerated = $Item.maxHeightGenerated
                Enabled            = $Item.enabled
            }
        }
    }
}

################################################################################
## Build Custom Generator List

$CustomGeneratorList = @()

ForEach ( $Validator in $Config.Validator ) {

    $HeightList = $GeneratorStatusList | Where-Object { $_.Address -eq $Validator.Address } | Select-Object -Property NodeName, Height, MaxHeightPrevoted, MaxHeightGenerated

    #---

    ForEach ( $PublicServiceNode in $Config.PublicServiceNode ) {

        $ValidatorLastBlockInfo = $NULL

        try {
            $ValidatorLastBlockInfo = Invoke-RestMethod -Uri "$($PublicServiceNode.URL)api/v3/blocks?generatorAddress=$($Validator.Address)&limit=1" -Method GET -TimeoutSec $TimeoutSec
        } catch {
            $ErrorMessage += "Connection to '$($PublicServiceNode.URL)' timeout.`r`n"
        }

        if ( $NULL -ne $ValidatorLastBlockInfo ) {

            $ValidatorLastBlockInfo = $ValidatorLastBlockInfo.data | Select-Object -Property Height, MaxHeightPrevoted, MaxHeightGenerated

            $HeightList += [PSCustomObject]@{
                NodeName           = $PublicServiceNode.Name
                Height             = $ValidatorLastBlockInfo.height
                MaxHeightPrevoted  = $ValidatorLastBlockInfo.maxHeightPrevoted
                MaxHeightGenerated = $ValidatorLastBlockInfo.maxHeightGenerated
            }
        }
    }

    #---

    $CustomGeneratorList += [PSCustomObject]@{

        Name       = $Validator.Name
        Address    = $Validator.Address
        HeightList = $HeightList

    }
}

################################################################################
## Show

Clear-Host

Write-Host 'LiskWatchDog 4 by ' -ForegroundColor White -NoNewline
Write-Host 'gr33ndrag0n' -ForegroundColor Green
Write-Host ''

Write-Host 'Network Name : ' -ForegroundColor Cyan -NoNewline
Write-Host $Config.NetworkName -ForegroundColor White -NoNewline
Write-Host '     Network TopHeight : ' -ForegroundColor Cyan -NoNewline
Write-Host $TopHeight -ForegroundColor White
Write-Host ''

#Write-Host '# Generator Last Block Values' -ForegroundColor Cyan

ForEach ( $CustomGenerator in $CustomGeneratorList ) {

    $CustomGenerator_TopHeight = $CustomGenerator.HeightList | `
            Select-Object -ExpandProperty Height | `
            Sort-Object -Unique -Descending | `
            Select-Object -First 1

    $CustomGenerator_TopMaxHeightPrevoted = $CustomGenerator.HeightList | `
            Select-Object -ExpandProperty MaxHeightPrevoted | `
            Sort-Object -Unique -Descending | `
            Select-Object -First 1

    $CustomGenerator_MaxHeightGenerated = $CustomGenerator.HeightList | `
            Select-Object -ExpandProperty MaxHeightGenerated | `
            Sort-Object -Unique -Descending | `
            Select-Object -First 1

    Write-Host "# $($CustomGenerator.Name) / $($CustomGenerator.Address)`r`n" -ForegroundColor Cyan

    Write-Host $( $( 'NodeName' ).PadRight(30) ) -NoNewline -ForegroundColor Magenta
    Write-Host $( $( 'Height' ).PadRight(20) ) -NoNewline -ForegroundColor Magenta
    Write-Host $( $( 'MaxHeightPrevoted' ).PadRight(20) ) -NoNewline -ForegroundColor Magenta
    Write-Host 'MaxHeightGenerated' -ForegroundColor Magenta
    Write-Host ''

    $CustomGenerator.HeightList | ForEach-Object {

        Write-Host $( $( $( $_.NodeName ).ToString() ).PadRight(30) ) -NoNewline
        if ( $_.Height -eq $CustomGenerator_TopHeight ) {
            Write-Host $( $( $( $_.Height ).ToString() ).PadRight(20) ) -NoNewline -ForegroundColor Green
        } else {
            Write-Host $( $( $( $_.Height ).ToString() ).PadRight(20) ) -NoNewline -ForegroundColor Yellow
        }
        if ( $_.MaxHeightPrevoted -eq $CustomGenerator_TopMaxHeightPrevoted ) {
            Write-Host $( $( $( $_.MaxHeightPrevoted ).ToString() ).PadRight(20) ) -NoNewline -ForegroundColor Green
        } else {
            Write-Host $( $( $( $_.MaxHeightPrevoted ).ToString() ).PadRight(20) ) -NoNewline -ForegroundColor Yellow
        }
        if ( $_.MaxHeightGenerated -eq $CustomGenerator_MaxHeightGenerated ) {
            Write-Host "$($_.MaxHeightGenerated)" -ForegroundColor Green
        } else {
            Write-Host "$($_.MaxHeightGenerated)" -ForegroundColor Yellow
        }
    }

    Write-Host ''
}

################################################################################
## Show Error

if ( $ErrorMessage -ne '' ) {
    Write-Host "`r`n$ErrorMessage" -ForegroundColor Red
}
