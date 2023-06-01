<#
.SYNOPSIS
    Show Dashboard

.PARAMETER Net
    Beta, Test, Main

.EXAMPLE
    .\Show-Dashboard.ps1 -Net Beta

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

Clear-Host

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
## Build Account List & Wallet Object

$AccountList = @()

ForEach ( $Account in $Config.Account ) {

    $Balance = $NULL

    $Balance = Invoke-RestMethod -Uri $Config.DefaultCoreAPI -Method GET -Body $( @{
            jsonrpc = '2.0'
            id      = '1'
            method  = 'token_getBalance'
            params  = @{
                address = $Account.Address
                tokenID = $Config.TokenID
            }
        } | ConvertTo-Json -Depth 100 -Compress )

    $PendingUnlocks = Invoke-RestMethod -Uri $Config.DefaultCoreAPI -Method GET -Body $( @{
            jsonrpc = '2.0'
            id      = '1'
            method  = 'pos_getPendingUnlocks'
            params  = @{
                address = $Account.Address
                tokenID = $Config.TokenID
            }
        } | ConvertTo-Json -Depth 100 -Compress )

    if ( ( $NULL -ne $Balance ) -and ( $NULL -ne $PendingUnlocks ) ) {

        $AvailableBalance = [System.Decimal]$( '{0:F2}' -f $( $Balance.result.availableBalance / 100000000 ) )
        $LockBalance = [System.Decimal]$( '{0:F2}' -f $( $( $Balance.result.lockedBalances.amount | Measure-Object -Sum | Select-Object -ExpandProperty Sum ) / 100000000 ) )

        #---

        #$PendingUnlocks.result.pendingUnlocks | Format-Table
        $PendingUnlockBalance = [System.Decimal]$( '{0:F2}' -f $( $( $PendingUnlocks.result.pendingUnlocks | Where-Object { $_.unlockable -eq $False } | Select-Object -ExpandProperty amount | Measure-Object -Sum | Select-Object -ExpandProperty Sum ) / 100000000 ) )
        $UnlockableBalance = [System.Decimal]$( '{0:F2}' -f $( $( $PendingUnlocks.result.pendingUnlocks | Where-Object { $_.unlockable -eq $True } | Select-Object -ExpandProperty amount | Measure-Object -Sum | Select-Object -ExpandProperty Sum ) / 100000000 ) )

        #--

        $AccountList += [PSCustomObject]@{
            Address              = $Account.Address
            Name                 = $Account.Name
            AvailableBalance     = $AvailableBalance
            LockBalance          = $LockBalance
            PendingUnlockBalance = $PendingUnlockBalance
            UnlockableBalance    = $UnlockableBalance
            TotalBalance         = $AvailableBalance + $LockBalance + $PendingUnlockBalance + $UnlockableBalance
        }
    }

}

$Wallet = [PSCustomObject]@{
    TotalAvailable     = $AccountList.AvailableBalance | Measure-Object -Sum | Select-Object -ExpandProperty Sum
    TotalLock          = $AccountList.LockBalance | Measure-Object -Sum | Select-Object -ExpandProperty Sum
    TotalPendingUnlock = $AccountList.PendingUnlockBalance | Measure-Object -Sum | Select-Object -ExpandProperty Sum
    TotalUnlockable    = $AccountList.UnlockableBalance | Measure-Object -Sum | Select-Object -ExpandProperty Sum
    Total              = $AccountList.TotalBalance | Measure-Object -Sum | Select-Object -ExpandProperty Sum
}

################################################################################
## Build Public Lisk-Core Node - Node Info

$PublicCoreNodeList = @()

ForEach ( $PublicCoreNode in $Config.PublicCoreNode ) {

    $NodeInfo = $NULL

    try {
        $NodeInfo = Invoke-RestMethod -Uri $PublicCoreNode.URL -Method GET -TimeoutSec $TimeoutSec -Body $( @{
                jsonrpc = '2.0'
                id      = '1'
                method  = 'system_getNodeInfo'
                params  = @{}
            } | ConvertTo-Json -Depth 100 -Compress )
    } catch {
        $ErrorMessage += "Connection to '$($PublicCoreNode.URL)' timeout.`r`n"
    }

    if ( $NULL -ne $NodeInfo ) {

        $NodeInfo = $NodeInfo.result

        $PublicCoreNodeList += [PSCustomObject]@{
            Name                    = $PublicCoreNode.Name
            Country                 = $PublicCoreNode.Country
            #URL                     = $PublicCoreNode.URL
            CoreVersion             = $NodeInfo.version
            NetworkVersion          = $NodeInfo.networkVersion
            ChainID                 = $NodeInfo.chainID
            Height                  = $NodeInfo.height
            FinalizedHeight         = $NodeInfo.finalizedHeight
            Syncing                 = $NodeInfo.syncing
            UnconfirmedTransactions = $NodeInfo.unconfirmedTransactions
        }
    }
}

################################################################################
## Build Private Lisk-Core Node - Node Info & Generator Status

$PrivateCoreNodeList = @()
$GeneratorStatusList = @()

ForEach ( $PrivateCoreNode in $Config.PrivateCoreNode ) {

    $NodeInfo = $NULL

    try {
        $NodeInfo = Invoke-RestMethod -Uri $PrivateCoreNode.URL -Method GET -TimeoutSec $TimeoutSec -Body $( @{
                jsonrpc = '2.0'
                id      = '1'
                method  = 'system_getNodeInfo'
                params  = @{}
            } | ConvertTo-Json -Depth 100 -Compress )
    } catch {
        $ErrorMessage += "Connection to '$($PrivateCoreNode.URL)' timeout.`r`n"
    }

    if ( $NULL -ne $NodeInfo ) {

        $NodeInfo = $NodeInfo.result

        $PrivateCoreNodeList += [PSCustomObject]@{
            Name                    = $PrivateCoreNode.Name
            #URL                     = $URL
            CoreVersion             = $NodeInfo.version
            NetworkVersion          = $NodeInfo.networkVersion
            ChainID                 = $NodeInfo.chainID
            Height                  = $NodeInfo.height
            FinalizedHeight         = $NodeInfo.finalizedHeight
            Syncing                 = $NodeInfo.syncing
            UnconfirmedTransactions = $NodeInfo.unconfirmedTransactions
            #ActiveGeneratorList        = TODO
        }
    }

    #---

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
## Build Validator List

$ValidatorList = @()

ForEach ( $Validator in $Config.Validator ) {

    $ValidatorCoreInfo = $NULL

    $ValidatorCoreInfo = Invoke-RestMethod -Uri $Config.DefaultCoreAPI -Method GET -Body $( @{
            jsonrpc = '2.0'
            id      = '1'
            method  = 'pos_getValidator'
            params  = @{
                address = $Validator.Address
            }
        } | ConvertTo-Json -Depth 100 -Compress )

    #---

    $ValidatorServiceInfo = $NULL

    $ValidatorServiceInfo = Invoke-RestMethod -Uri "$($Config.DefaultServiceAPI)api/v3/pos/validators?address=$($Validator.Address)" -Method GET -TimeoutSec $TimeoutSec

    #---

    $GeneratorServiceInfo = $NULL

    $GeneratorServiceInfo = Invoke-RestMethod -Uri "$($Config.DefaultServiceAPI)api/v3/generators?search=$($Validator.Address)" -Method GET -TimeoutSec $TimeoutSec

    #---

    if ( ( $NULL -ne $ValidatorCoreInfo ) -and ( $NULL -ne $ValidatorServiceInfo ) -and ( $NULL -ne $GeneratorServiceInfo ) ) {

        $ValidatorCoreInfo = $ValidatorCoreInfo.result
        $ValidatorServiceInfo = $ValidatorServiceInfo.data
        $GeneratorServiceInfo = $GeneratorServiceInfo.data

        $Rank = $ValidatorServiceInfo | Select-Object -ExpandProperty rank
        $SelfStake = [System.Decimal]$( '{0:F2}' -f $( $ValidatorCoreInfo.selfStake / 100000000 ) )
        $TotalStake = [System.Decimal]$( '{0:F2}' -f $( $ValidatorCoreInfo.totalStake / 100000000 ) )

        $LastBlockCount = $TopHeight - $ValidatorCoreInfo.lastGeneratedHeight

        $NextBlockDate = $( $( Get-Date 01.01.1970 ) + ( [System.TimeSpan]::fromseconds( $GeneratorServiceInfo.nextAllocatedTime ) ) )
        $NextBlockDelay = $( $NextBlockDate - $( Get-Date -AsUTC ) ).TotalSeconds
        $NextBlockDelay = [System.Decimal]$( '{0:F2}' -f $NextBlockDelay )

        $ActiveNode = $GeneratorStatusList | Where-Object { ( $_.Address -eq $Validator.Address ) -and ( $_.Enabled -eq $true ) } | Select-Object -ExpandProperty NodeName

        #--

        $ValidatorList += [PSCustomObject]@{
            Address             = $ValidatorCoreInfo.address
            Name                = $ValidatorCoreInfo.name
            Rank                = $Rank
            Status              = $ValidatorServiceInfo.Status
            GeneratorActiveNode = $ActiveNode
            LastBlockCount      = $LastBlockCount
            NextBlockDelay      = $NextBlockDelay
            MissedBlocks        = $ValidatorCoreInfo.consecutiveMissedBlocks
            SelfStake           = $SelfStake
            TotalStake          = $TotalStake
            GeneratedBlocks     = $ValidatorServiceInfo.generatedBlocks
            IsBanned            = $ValidatorCoreInfo.isBanned
        }
    }
}

$ValidatorList = $ValidatorList | Sort-Object -Property Rank

################################################################################
## Show Dashboard

Write-Host 'LiskWatchDog 4 by ' -ForegroundColor White -NoNewline
Write-Host 'gr33ndrag0n' -ForegroundColor Green
Write-Host ''

Write-Host 'Network Name : ' -ForegroundColor Cyan -NoNewline
Write-Host $Config.NetworkName -ForegroundColor White -NoNewline
Write-Host '     Network TopHeight : ' -ForegroundColor Cyan -NoNewline
Write-Host $TopHeight -ForegroundColor White
Write-Host ''

Write-Host '# Account' -ForegroundColor Cyan
$AccountList | Format-Table -Property *
$Wallet | Format-Table -Property *

Write-Host '# Validator' -ForegroundColor Cyan
$ValidatorList | Format-Table -Property *

Write-Host '# Public Lisk-Core Node - Node Info' -ForegroundColor Cyan
$PublicCoreNodeList | Format-Table -Property *

Write-Host '# Private Lisk-Core Node - Node Info' -ForegroundColor Cyan
$PrivateCoreNodeList | Format-Table -Property *

################################################################################
## Show Error

if ( $ErrorMessage -ne '' ) {
    Write-Host "`r`n$ErrorMessage" -ForegroundColor Red
}
