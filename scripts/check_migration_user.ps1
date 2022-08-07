#!/usr/bin/env pwsh
#Requires -Version 7
[CmdletBinding(DefaultParameterSetName="EmailAddress")]
param ( 
    [parameter(Mandatory=$false,ParameterSetName="EmailAddress",Position=0)]
    [string]
    $EmailAddress,

    [parameter(Mandatory=$false,ParameterSetName="PrimaryDomain")]
    [string]
    $Alias,

    [parameter(Mandatory=$false,ParameterSetName="PrimaryDomain")]
    [string]
    $PrimaryDomain,

    [parameter(Mandatory=$false)]
    [string]
    $DeliveryDomain
) 
. (Join-Path $PSScriptRoot functions.ps1)

# Process input
switch ($PSCmdlet.ParameterSetName) {
    "EmailAddress" {
        $EmailAddress = $EmailAddress.ToLower()
        $Alias = $EmailAddress.Split("@")[0]
        $PrimaryDomain = $EmailAddress.Split("@")[1]
    }
    "PrimaryDomain" {
        if ($Alias -and $PrimaryDomain) {
            $EmailAddress = "${Alias}@${PrimaryDomain}"
        }
    }
}
if (!$DeliveryDomain) {
    $DeliveryDomain = "office365.${PrimaryDomain}"
}
if ($Alias -and $DeliveryDomain) {
    $deliveryEmailAddress = "${Alias}@${DeliveryDomain}"
}

# Start session
Login-ExchangeOnline

# Check migration endpoint(s)
Get-MigrationEndpoint | Where-Object { !$_.IsValid } | Set-Variable invalidEdpoints
if ($invalidEdpoints) {
    Write-Warning "Found ${invalidEdpoints.Count} invalid migration endpoints:"
    $invalidEdpoints | Sort-Properties | Format-List    

    pause
}

# Get sync statistics for user
if ($deliveryEmailAddress) {
    Get-SyncRequest -Mailbox $deliveryEmailAddress | Get-SyncRequestStatistics -IncludeReport -DiagnosticInfo "showtimeslots, showtimeline, verbose" `
                                                   | Where-Object { ($_.DataConsistencyScore -inotin "Good", "Perfect") -or !$_.IsValid } `
                                                   | Set-Variable syncRequestStats
    if ($syncRequestStats) {
        Write-Warning "Sync request ${deliveryEmailAddress} has data consistency score '$($syncRequestStats.DataConsistencyScore.ToString())'"

        New-TemporaryFile | Select-Object -ExpandProperty FullName | Set-Variable syncRequestStatsFile
        $syncRequestStatsFile -replace ".tmp",".xml" | Set-Variable syncRequestStatsFile
        $syncRequestStats | Sort-Properties `
                          | Select-Object -Property BatchName,BytesTransferred,DataConsistencyScore,DataConsistencyScoringFactors,EmailAddress,EstimatedTransferItemCount,EstimatedTransferSize,ForwardingDisposition,IsValid,ItemsTransferred,Name,RecipientTypeDetails,Status,StatusDetail,TargetAlias `
                          | Format-List
        $syncRequestStats | Export-Clixml $syncRequestStatsFile
        Write-Host "`nFull sync request statistics for user ${deliveryEmailAddress}: $syncRequestStatsFile"

        pause
    }
}

# Get migration statistics for user
if ($EmailAddress) {
    Get-MigrationUserStatistics $EmailAddress -IncludeSkippedItems -IncludeReport -DiagnosticInfo "showtimeslots, showtimeline, verbose" | Set-Variable migrationUserStats
    New-TemporaryFile | Select-Object -ExpandProperty FullName | Set-Variable migrationUserStatsFile
    $migrationUserStatsFile -replace ".tmp",".xml" | Set-Variable migrationUserStatsFile
    $migrationUserStats | Sort-Properties | Write-Verbose
    $migrationUserStats | Export-Clixml $migrationUserStatsFile
    Write-Host "`nFull migration statistics for user ${EmailAddress}: $migrationUserStatsFile"

    $migrationUserStats.SkippedItems | Set-Variable skippedItems
    if ($skippedItems) {
        $skippedItems | Measure-Object | Select-Object -ExpandProperty Count | Set-Variable skippedItemsCount
        Write-Warning "Found $skippedItemsCount skipped items for ${EmailAddress}:"
        $skippedItems | Format-Table Subject, Sender, DateSent, ScoringClassifications

        pause
    }
}

# Get migration user
if ($EmailAddress) {
    Write-Verbose "Migration batch ${EmailAddress}:"
    Get-MigrationBatch -Identity $EmailAddress | Where-Object { ($_.DataConsistencyScore -inotin "Good", "Perfect") -or !$_.IsValid } | Set-Variable migrationBatch
    if ($migrationBatch) {
        Write-Warning "Migration batch ${EmailAddress} has data consistency score '$($migrationBatch.DataConsistencyScore.ToString())'"
        $migrationBatch | Sort-Properties | Write-Verbose
        $migrationBatch | Format-List -Property BatchDirection,Identity,IsValid,Status,State,DataConsistencyScore,StartDateTime,TargetDeliveryDomain,WorkflowStage

        pause
    }

    Write-Verbose "Migration user ${EmailAddress}:"
    Get-MigrationUser -Identity $EmailAddress | Where-Object { $_.DataConsistencyScore -inotin "Good", "Perfect" } | Set-Variable migrationUser
    if ($migrationUser) {
        Write-Warning "Migration user ${EmailAddress} has data consistency score '$($migrationUser.DataConsistencyScore.ToString())'"
        $migrationUser | Sort-Properties
    }
}
