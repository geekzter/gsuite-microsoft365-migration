# gsuite-microsoft365-migration

## Pre-requisites
- Pre-requisites as documented in the [Google Workspace migration prerequisites in Exchange Online guide](https://docs.microsoft.com/en-us/exchange/mailbox-migration/googleworkspace-migration-prerequisites)
- Configure [domain-wide access](https://developers.google.com/admin-sdk/directory/v1/guides/delegation)
- [Enable](https://support.google.com/googleapi/answer/6158841?hl=en) the following API's:
    - Calendar API
    - Contacts API
    - Gmail API
    - People API
- [Grant access to the service account for your Google tenant](https://docs.microsoft.com/en-gb/exchange/mailbox-migration/manually-configuring-gsuite-for-migration#grant-access-to-the-service-account-for-your-google-tenant)


## Known issues
# GmailForwardingAddressRequiresVerificationException
If you run into this issue, try any of these solutions:
- Do not use a `<tenantname`>.onmicrosoft.com domain (if you did not [read the pre-requisites](https://docs.microsoft.com/en-GB/exchange/mailbox-migration/googleworkspace-migration-prerequisites#create-a-subdomain-for-mail-routing-to-microsoft-365-or-office-365))
- In Google Workspace, [set up routing for your domain or organization](https://support.google.com/a/answer/6297084)
- The previous option is not available in GSuite free edition. In this case you have to ask each migrated user to click the validation link sent to their inbox.

# Automatic forwarding is denied on Office 365
Even if you have a remote domain 'Default' set up to allow automatic forwarding, you run into this error:   
`Access denied, Your organization does not allow external forwarding. Please contact your administrator for further assistance. AS(7555)`   

Just add another remote domain for your Office 365 delivery domain (e.g. office365.`<yourdomain`>.com)