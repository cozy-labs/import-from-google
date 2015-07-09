cozydb = require 'cozydb'

module.exports = Album = cozydb.getModel 'Account',
    label: String               # human readable label for the account
    name: String                # user name to put in sent mails
    login: String               # IMAP & SMTP login
    password: String            # IMAP & SMTP password
    accountType: String         # "IMAP" or "TEST"
    oauthProvider: String       # GMAIL (only for the moment)
    oauthRefreshToken: String   # RefreshToken (in order to get an access_token)
    oauthAccessToken: String   # RefreshToken (in order to get an access_token)
    initialized: Boolean        # Is the account ready ? (usefull for the moment
                                # only for leave google app)
    smtpServer: String          # SMTP host
    smtpPort: Number            # SMTP port
    smtpSSL: Boolean            # Use SSL
    smtpTLS: Boolean            # Use STARTTLS
    smtpLogin: String           # SMTP login, if different from default
    smtpPassword: String        # SMTP password, if different from default
    smtpMethod: String          # SMTP Auth Method
    imapLogin: String           # IMAP login
    imapServer: String          # IMAP host
    imapPort: Number            # IMAP port
    imapSSL: Boolean            # Use SSL
    imapTLS: Boolean            # Use STARTTLS
    inboxMailbox: String        # INBOX Maibox id
    flaggedMailbox: String      # \Flag Mailbox id
    draftMailbox: String        # \Draft Maibox id
    sentMailbox: String         # \Sent Maibox id
    trashMailbox: String        # \Trash Maibox id
    junkMailbox: String         # \Junk Maibox id
    allMailbox: String          # \All Maibox id
    favorites: [String]         # [String] Maibox id of displayed boxes
    patchIgnored: Boolean       # has patchIgnored been applied ?
    signature: String           # Signature to add at the end of messages

