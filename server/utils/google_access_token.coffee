request = require 'request-json'
querystring = require 'querystring'
log = require('printit')
    date: true
    prefix: 'utils:gat'

client = request.createClient 'https://www.googleapis.com/oauth2/v3/token'
client.headers['Content-Type'] = 'application/x-www-form-urlencoded'

data =
    client_secret: "1gNUceDM59TjFAks58ftsniZ"
    redirect_uri: "urn:ietf:wg:oauth:2.0:oob"
    grant_type: "authorization_code"
    client_id: """
260645850650-2oeufakc8ddbrn8p4o58emsl7u0r0c8s.apps.googleusercontent.com"""

scopes = [
    'https://www.googleapis.com/auth/calendar.readonly'
    'https://picasaweb.google.com/data/'
    'https://www.googleapis.com/auth/contacts.readonly'
    'email'
    'https://mail.google.com/'
    'profile'
]

google = require 'googleapis'
OAuth2 = google.auth.OAuth2
oauth2Client = new OAuth2 data.client_id, data.client_secret, data.redirect_uri

module.exports.oauth2Client = oauth2Client

module.exports.getAuthUrl = ->
    oauth2Client.generateAuthUrl scope: scopes

module.exports.generateRequestToken = (authCode, callback)->
    data.code = authCode
    urlEncodedData = querystring.stringify data
    log.debug "requestToken #{authCode}"
    client.post "?#{urlEncodedData}", data, (err, res, body)->
        log.debug "gotToken", body
        callback err, body
