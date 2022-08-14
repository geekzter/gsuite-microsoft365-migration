#!/usr/bin/env pwsh
#Requires -Version 7
. (Join-Path $PSScriptRoot functions.ps1)

Login-ExchangeOnline


# Get migration users
Write-Verbose "Migration user ${emailAddress}:"
Get-MigrationBatch | Set-Variable migrationBatches
if ($migrationBatches) {
    Write-Warning "`nMigration batches:"
    # $migrationBatches | Format-Table -Property MailboxEmailAddress,DataConsistencyScore,HasUnapprovedSkippedItems,SyncedItemCount,SkippedItemCount,State,Status,StatusSummary
    $migrationBatches | Format-Table -Property Identity,Status,State,DataConsistencyScore,WorkflowStage,BatchDirection,IsValid
}