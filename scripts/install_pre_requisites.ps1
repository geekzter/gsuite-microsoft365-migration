#!/usr/bin/env pwsh

Install-Module -Name PowerShellGet
Install-Module -Name ExchangeOnlineManagement

if ($IsMacOS) {
    Install-Module -Name PSWSMan
    sudo pwsh -Command 'Install-WSMan' -NoLogo -NoProfile 
}
