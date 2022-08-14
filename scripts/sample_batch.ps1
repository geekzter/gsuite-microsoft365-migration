#!/usr/bin/env pwsh

#Requires -Version 7

. (Join-Path $PSScriptRoot functions.ps1)

Login-ExchangeOnline

Join-Path (Split-Path $PSScriptRoot -Parent) "projectid-myid.json" | Set-Variable credentialFile
$env:GOOGLE_APPLICATION_CREDENTIALS = $credentialFile

$deliveryDomain = "office365.mydomain.com"
$endpoint = "Gsuite2Office365"
# Get-MigrationEndpoint -Identity $endpoint
Create-GoogleMigrationBatch -Alias myuseralias `
                            -Domain "mydomain.com" `
                            -Endpoint $endpoint `
                            -DeliveryDomain $deliveryDomain `
                            -ApproveSkippedItems:$false
