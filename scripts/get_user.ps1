#!/usr/bin/env pwsh
param ( 
    [parameter(Mandatory=$true)][string]$Name
) 
. (Join-Path $PSScriptRoot functions.ps1)

Login-ExchangeOnline

Get-MailUser -Identity $Name -ErrorAction SilentlyContinue | Set-Variable user
if (!$user) {
    Get-EXOMailBox -Identity $Name -ErrorAction SilentlyContinue | Set-Variable user
}
$user | Sort-Properties | Format-List