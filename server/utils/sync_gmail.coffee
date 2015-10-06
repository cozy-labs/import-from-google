Account = require '../models/account'
google = require 'googleapis'
plus = google.plus('v1')
{oauth2Client} = require './google_access_token'




module.exports = (access_token, refresh_token, force, callback)->

    oauth2Client.setCredentials
        access_token: access_token

    plus.people.get { userId: 'me', auth: oauth2Client }, (err, profile)->

        account =
            label: "GMAIL oauth2"
            name: profile.displayName
            login: profile.emails[0].value
            oauthProvider: "GMAIL"
            initialized: false
            oauthAccessToken: access_token
            oauthRefreshToken: refresh_token
            # RefreshToken (in order to get an access_token)

        email = profile.emails[0].value
        Account.request 'byEmailWithOauth', key: email, (err, fetchedAccounts)->
            return callback err if err
            unless fetchedAccounts.length is 0
                newAttr = {oauthRefreshToken: refresh_token}
                fetchedAccounts[0].updateAttributes newAttr, (err)->
                    callback err, fetchedAccounts[0]
            else if force
                Account.create account, (err, account) ->
                    callback err, account
            else
                callback()
