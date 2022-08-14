# GSuite to Microsoft 365 migration
After 15 years, Google has finally [pulled the plug](https://support.google.com/a/answer/60217#faq) on ~~Google Apps~~ 'GSuite legacy free edition'. It was great while it lasted, and I thank Google for being so lenient to its early adoptors for so long.
Now it is time to pay up, you may as well consider alternatives. While I love Gmail, I chose the market leader: Microsoft 365.

Microsoft has a ton of documentation on GSuite to Microsoft 365 migration. There is a [landing page](https://docs.microsoft.com/en-us/Exchange/mailbox-migration/perform-g-suite-migration) and an [overview of the migration process](https://docs.microsoft.com/en-gb/exchange/mailbox-migration/how-it-all-works-in-the-backend).

This repo does not aim to replace documentation. Rather, it contains a number of helper scripts I used to migrate from GSuite to Microsoft 365. This was a one-time event, so it is not something I'll be maintaining.

## Pre-requisites
- Pre-requisites as documented in the [Google Workspace migration prerequisites in Exchange Online guide](https://docs.microsoft.com/en-us/exchange/mailbox-migration/googleworkspace-migration-prerequisites)
- Configure [domain-wide access](https://developers.google.com/admin-sdk/directory/v1/guides/delegation) in GSuite
- [Enable](https://support.google.com/googleapi/answer/6158841?hl=en) the following GSuite API's:
    - Calendar API
    - Contacts API
    - Gmail API
    - People API
- [Grant access to the service account for your Google tenant](https://docs.microsoft.com/en-gb/exchange/mailbox-migration/manually-configuring-gsuite-for-migration#grant-access-to-the-service-account-for-your-google-tenant)

## Migration
Follow [the documentation](https://docs.microsoft.com/en-gb/exchange/mailbox-migration/perform-g-suite-migration).

### Scripts
- [sample_batch.ps1](./scripts/sample_batch.ps1) creates a sample migration batch with 1 user
- [check_migration_batches.ps1](./scripts/check_migration_batches.ps1) checks migration batches
- [check_migration_users.ps1](./scripts/check_migration_users.ps1) checks individual users, and lusts skipped migration items

## Known issues
### GmailForwardingAddressRequiresVerificationException
If you run into this issue, try any of these solutions:
- Do not use a `<tenantname`>.onmicrosoft.com domain (and [read the pre-requisites](https://docs.microsoft.com/en-GB/exchange/mailbox-migration/googleworkspace-migration-prerequisites#create-a-subdomain-for-mail-routing-to-microsoft-365-or-office-365))
- Assign licenses before completing the migration batch
- In Google Workspace, [set up routing for your domain or organization](https://support.google.com/a/answer/6297084)
- The previous option is not available in GSuite free edition. In this case you have to ask each migrated user to click the validation link sent to their inbox.

### Automatic forwarding is denied on Microsoft 365
Even if you have a remote domain 'Default' set up to allow automatic forwarding, you can run into this error:   
`Access denied, Your organization does not allow external forwarding. Please contact your administrator for further assistance. AS(7555)`   

Just add another remote domain for your Microsoft 365 delivery domain (e.g. office365.`<yourdomain`>.com)

## Other GSuite decommisioning tasks
As you plan to abanodon GSuite, realize a Google Account is used for a lot more than GSuite:
- A Google Account can be used to sign into 3rd party applications (e.g., Feedly). Check any [apps or sites](https://myaccount.google.com/permissions) that a user logs in to. That will no longer be possible with the Google Account in GSuite.
- Use Google [Takeout](https://takeout.google.com/) to download any data that may not have been migrated
- Users may want a personal Google Account to continue using 1st party Google Apps (e.g., YouTube).
While takeout exports Google 1st part app data, there is not straightforward process to re-import playlists, subscriptions, etc.