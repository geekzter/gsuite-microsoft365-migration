function Create-GoogleMigrationBatch(
    [parameter(Mandatory=$true)][string[]]$Alias,
    [parameter(Mandatory=$true)][string]$Domain,
    [parameter(Mandatory=$false)][string]$DeliveryDomain="office365${Domain}",
    [parameter(Mandatory=$false)][string]$EndpointName="Gsuite2Office365",
    [parameter(Mandatory=$false)][string]$CredentialFile=$env:GOOGLE_APPLICATION_CREDENTIALS
) {

    [System.Collections.ArrayList]$emailAddresses = @()
    foreach ($a in $Alias) {
        $emailAddresses.Add("${a}@${Domain}") | Out-Null
    }

    Write-Debug "Testing migration server availability with email address $($emailAddresses[0])..."
    Test-MigrationServerAvailability -Gmail -ServiceAccountKeyFileData $([System.IO.File]::ReadAllBytes($CredentialFile)) -EmailAddress $emailAddresses[0]
    Write-Debug "Migration server availability test successful"
    
    Write-Debug "Creating CSV file with batch contents..."
    $csvFile = New-TemporaryFile
    Set-Content -Value "EmailAddress" -Path $csvFile
    foreach ($emailAddress in $emailAddresses) {
        Add-Content -Value $emailAddress -Path $csvFile
    }
    Get-Content $csvFile | Out-String | Write-Verbose

    $batchName = $emailAddresses[0]

    Get-MigrationBatch -Identity $batchName -ErrorAction SilentlyContinue | Set-Variable batch
    if (!$batch) {
        Write-Debug "Creating batch ${batchName}..."
        New-MigrationBatch -Name $batchName -CSVData $([System.IO.File]::ReadAllBytes($csvFile)) `
                           -SourceEndpoint $EndpointName `
                           -TargetDeliveryDomain $DeliveryDomain | Set-Variable batch
    }
    $batch | Sort-Properties | Format-List

    if ($batch.State -eq "Completed") {
        Write-Warning "Batch ${batchName} is already completed"
    } else {
        Write-Verbose "Starting batch ${batchName}..."
        Start-MigrationBatch -Identity $batchName
    }
}

function Create-MailUser(
    [parameter(Mandatory=$true)][string]$Alias,
    [parameter(Mandatory=$true)][string]$FirstName,
    [parameter(Mandatory=$true)][string]$LastName,
    [parameter(Mandatory=$true)][string]$PrimaryDomain,
    [parameter(Mandatory=$true)][string]$ExternalDomain,
    [parameter(Mandatory=$true)][string[]]$SecondaryDomain
) {
    Get-SecurityPrincipal -Filter "Alias -eq '${Alias}'" | Set-Variable existingUser
    if ($existingUser -and ($existingUser.RecipientTypeDetails -ne 'MailUser')) {
        Write-Error "${Alias} already exists as a $($existingUser.RecipientTypeDetails)"
        return
    }

    $emailAddress = "${Alias}@${PrimaryDomain}"
    $fullName = $FirstName + " " + $LastName;
    if (!$existingUser) {
        Write-Host "Creating Mail user ${emailAddress}..."
        [guid]::NewGuid().ToString() | ConvertTo-SecureString -AsPlainText -Force | Set-Variable password
        New-MailUser -Alias $Alias `
                     -Name $fullName `
                     -DisplayName "${fullName} (created with New-MailUser)" `
                     -FirstName $FirstName `
                     -LastName $LastName `
                     -MicrosoftOnlineServicesID $emailAddress `
                     -Password $password

        Write-Host "Created Mail user $emailAddress"
    }

    Get-MailUser -Identity $Alias | Set-Variable mailUser

    $externalEmailAddress = $ExternalDomain ? "${Alias}@${ExternalDomain}" : $null
    [System.Collections.ArrayList]$emailAddresses = @("smtp:${emailAddress}")
    # $emailAddresses = $mailUser.emailAddresses
    Write-Debug "`$emailAddresses: $emailAddresses"
    foreach ($domain in $SecondaryDomain) {
        $secondaryEmailAddress = "smtp:${Alias}@${domain}"
        if (($secondaryEmailAddress -inotin $emailAddresses) -and ("smtp:${secondaryEmailAddress}" -inotin $emailAddresses)) {
            $emailAddresses.Add($secondaryEmailAddress) | Out-Null
            $updateMailUser = $true
        }
    }

    if ($updateMailUser) {
        Write-Debug "`$emailAddresses: $emailAddresses"
        Write-Verbose "Updating Mail user ${emailAddress}..."
        Set-MailUser -Identity $Alias `
                     -EmailAddresses $emailAddresses `
                     -ExternalEmailAddress $externalEmailAddress `
                     -MicrosoftOnlineServicesID $emailAddress
    }

    if ($DebugPreference -ieq "Continue") {
        Get-MailUser -Identity $Alias | Sort-Properties | Format-List | Out-String | Write-Debug
    }
}

function Login-ExchangeOnline () {
    Get-PSSession | Where-Object Name -match "ExchangeOnline" `
                  | Where-Object State -ieq Opened `
                  | Set-Variable session

    $login = $false
    if ($session) {
        if (-not (Get-OrganizationConfig -ErrorAction SilentlyContinue)) {
            $login = $true
        }
    } else {
        $login = $true
    }

    if ($login) {
        Connect-ExchangeOnline
    }
}

function Sort-Properties (
    [parameter(Mandatory=$true,ValueFromPipeline=$true)][object]$Object
) {
    if ($Object) {
        $Object | Select-Object ([string[]]($Object | Get-Member -MemberType Property | %{ $_.Name } | Sort-Object))
    }
}