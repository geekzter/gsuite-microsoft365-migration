
function Create-MailUser(
    [parameter(Mandatory=$true)][string]$Alias,
    [parameter(Mandatory=$true)][string]$FirstName,
    [parameter(Mandatory=$true)][string]$LastName,
    [parameter(Mandatory=$true)][string]$PrimaryDomain,
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
                     -ExternalEmailAddress $emailAddress `
                     -FirstName $FirstName `
                     -LastName $LastName `
                     -MicrosoftOnlineServicesID $emailAddress `
                     -Password $password

        Write-Host "Created Mail user $emailAddress"
    }

    Get-MailUser -Identity $Alias | Set-Variable mailUser

    $emailAddresses = $mailUser.emailAddresses
    Write-Debug "`$emailAddresses: $emailAddresses"
    foreach ($domain in $SecondaryDomain) {
        $secondaryEmailAddress = "${Alias}@${domain}"
        if (($secondaryEmailAddress -inotin $emailAddresses) -and ("smtp:${secondaryEmailAddress}" -inotin $emailAddresses)) {
            $emailAddresses.Add($secondaryEmailAddress) | Out-Null
            $updateMailUser = $true
        }
    }

    if ($updateMailUser) {
        Write-Debug "`$emailAddresses: $emailAddresses"
        Write-Verbose "Updating Mail user ${emailAddress}..."
        Set-MailUser -Identity $Alias -EmailAddresses $emailAddresses
    }

    if ($DebugPreference -ieq "Continue") {
        Get-MailUser -Identity $Alias | Sort-Properties | Format-List | Out-String | Write-Debug
    }
}

function Login-ExchangeOnline () {
    Get-PSSession | Where-Object Name -match "ExchangeOnline" `
                  | Where-Object State -ieq Opened `
                  | Set-Variable session

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
    $Object | Select-Object ([string[]]($Object | Get-Member -MemberType Property | %{ $_.Name } | Sort-Object))
}