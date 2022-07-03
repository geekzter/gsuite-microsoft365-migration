
function Create-MailUser(
    [parameter(Mandatory=$true)][string]$Alias,
    [parameter(Mandatory=$true)][string]$FirstName,
    [parameter(Mandatory=$true)][string]$LastName,
    [parameter(Mandatory=$true)][string]$PrimaryDomain
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
