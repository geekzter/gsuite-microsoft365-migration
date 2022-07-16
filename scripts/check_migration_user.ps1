#!/usr/bin/env pwsh
#Requires -Version 7
param ( 
    [parameter(Mandatory=$false)][string]$Alias,
    [parameter(Mandatory=$false)][string]$PrimaryDomain,
    [parameter(Mandatory=$false)][string]$DeliveryDomain="office365.${PrimaryDomain}"
) 
. (Join-Path $PSScriptRoot functions.ps1)

Login-ExchangeOnline

if ($Alias -and $PrimaryDomain) {
    $emailAddress = "${Alias}@${PrimaryDomain}"
}
if ($Alias -and $DeliveryDomain) {
    $deliveryEmailAddress = "${Alias}@${DeliveryDomain}"
}

# Check migration endpoint(s)
Get-MigrationEndpoint | Where-Object { !$_.IsValid } | Set-Variable invalidEdpoints
if ($invalidEdpoints) {
    Write-Warning "Found ${invalidEdpoints.Count} invalid migration endpoints:"
    $invalidEdpoints | Sort-Properties | Format-List    

    pause
}

# Get migration statistics for user
if ($emailAddress) {
    Get-MigrationUserStatistics $emailAddress -IncludeSkippedItems -IncludeReport -DiagnosticInfo "showtimeslots, showtimeline, verbose" | Set-Variable migrationUserStats
    New-TemporaryFile | Select-Object -ExpandProperty FullName | Set-Variable migrationUserStatsFile
    $migrationUserStatsFile -replace ".tmp",".xml" | Set-Variable migrationUserStatsFile
    $migrationUserStats | Sort-Properties | Write-Verbose
    $migrationUserStats.Report.BadItems | Set-Variable skippedItems
    $migrationUserStats | Export-Clixml $migrationUserStatsFile
    Write-Host "`nFull migration statistics for user ${emailAddress}: $migrationUserStatsFile"

    if ($skippedItems) {
        $skippedItems | Measure-Object | Select-Object -ExpandProperty Count | Set-Variable skippedItemsCount
        Write-Warning "`nFound $skippedItemsCount skipped items for ${emailAddress}:"
        $skippedItems | Format-Table foldername,subject,failure

        pause
    }
}

# Get sync statistics for user
if ($deliveryEmailAddress) {
    Get-SyncRequest -Mailbox $deliveryEmailAddress | Get-SyncRequestStatistics -IncludeReport -DiagnosticInfo "showtimeslots, showtimeline, verbose" `
                                                   | Where-Object { ($_.DataConsistencyScore -inotin "Good", "Perfect") -or !$_.IsValid } `
                                                   | Set-Variable syncRequestStats
    if ($syncRequestStats) {
        Write-Warning "`nSync request ${deliveryEmailAddress} has data consistency score '$($syncRequestStats.DataConsistencyScore.ToString())'"

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

# Get migration user
if ($emailAddress) {
    Write-Verbose "Migration batch ${emailAddress}:"
    Get-MigrationBatch -Identity $emailAddress | Where-Object { ($_.DataConsistencyScore -inotin "Good", "Perfect") -or !$_.IsValid } | Set-Variable migrationBatch
    if ($migrationBatch) {
        Write-Warning "`nMigration batch ${emailAddress} has data consistency score '$($migrationBatch.DataConsistencyScore.ToString())'"
        $migrationBatch | Sort-Properties | Write-Verbose
        $migrationBatch | Format-List -Property BatchDirection,Identity,IsValid,Status,State,DataConsistencyScore,StartDateTime,TargetDeliveryDomain,WorkflowStage

        pause
    }

    Write-Verbose "Migration user ${emailAddress}:"
    Get-MigrationUser -Identity $emailAddress | Where-Object { $_.DataConsistencyScore -inotin "Good", "Perfect" } | Set-Variable migrationUser
    if ($migrationUser) {
        Write-Warning "`nMigration user ${emailAddress} has data consistency score '$($migrationUser.DataConsistencyScore.ToString())'"
        $migrationUser | Sort-Properties

        pause
    }
}
