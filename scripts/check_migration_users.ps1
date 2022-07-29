#!/usr/bin/env pwsh
#Requires -Version 7
param ( 
    [parameter(Mandatory=$false)][switch]$BadDataConsistencyScore
) 
. (Join-Path $PSScriptRoot functions.ps1)

Login-ExchangeOnline


# Get migration users
Write-Verbose "Migration user ${emailAddress}:"
Get-MigrationUser | Set-Variable migrationUsers
if ($BadDataConsistencyScore) {
    $migrationUsers | Where-Object { $_.DataConsistencyScore -inotin "Good", "Perfect" } | Set-Variable migrationUsers
    Write-Warning "`nMigration users with bad data consistency score:"
} else {
    Write-Host "`nMigration users:"
}
if ($migrationUsers) {
    $migrationUsers | Format-Table -Property MailboxEmailAddress,DataConsistencyScore,HasUnapprovedSkippedItems,SyncedItemCount,SkippedItemCount,State,Status,StatusSummary
}