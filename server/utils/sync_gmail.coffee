Account = require '../models/account'
google = require 'googleapis'
plus = google.plus('v1')
{oauth2Client} = require './google_access_token'




module.exports = (access_token, refresh_token, callback)->

    oauth2Client.setCredentials
        access_token: access_token

    plus.people.get { userId: 'me', auth: oauth2Client }, (err, profile)->

        account =
            label: "GMAIL oauth2"
            name: profile.displayName
            login: profile.emails[0]?.value
            oauthProvider: "GMAIL"
            initialized: false
            oauthRefreshToken: refresh_token   # RefreshToken (in order to get an access_token)

        Account.create account, (err, account) ->
            callback err, account
