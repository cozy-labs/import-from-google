async = require 'async'
cozydb = require 'cozydb'
googleToken = require '../utils/google_access_token'
importCalendar = require '../utils/import_calendar'
importContacts = require '../utils/import_contacts'
importPhotos = require '../utils/import_photos'
log = require('printit')('leaveGcontroller')
realtimer = require '../utils/realtimer'
syncGmail = require '../utils/sync_gmail'

module.exports.index = (req, res) ->
    url = googleToken.getAuthUrl()
    cozydb.api.getCozyLocale (err, locale) ->
        res.render 'index', imports: """
            window.oauthUrl = "#{url}";
            window.locale = "#{locale}";
        """

module.exports.lg = (req, res, next) ->

    res.send 200

    {auth_code, scope} = req.body
    #scope is like this :
    # scope: { photos: 'true', calendars: 'false', contacts: 'true'}
    # in this case we import only photos and contacts

    googleToken.generateRequestToken auth_code, (err, tokens) ->
        log.error err if err

        unless tokens?.access_token
            console.log "No access token"
            realtimer.sendEnd "invalid token"
            return

        async.series [
            (callback) ->
                syncGmail tokens.access_token, tokens.refresh_token,
                    scope.sync_gmail is 'true', (err) ->
                        if scope.sync_gmail is 'true'
                            realtimer.sendEnd "syncGmail.end"
                        callback null
            (callback) ->
                return callback null unless scope.photos is 'true'
                importPhotos tokens.access_token, (err) ->
                    realtimer.sendPhotosErr err if err
                    realtimer.sendEnd "photos.end"
                    callback null
            (callback) ->
                return callback null unless scope.calendars is 'true'
                importCalendar tokens.access_token, (err) ->
                    realtimer.sendCalendarErr err if err
                    realtimer.sendEnd "events.end"
                    callback null

            (callback) ->
                return callback null unless scope.contacts is 'true'
                importContacts tokens.access_token, (err) ->
                    realtimer.sendContactsErr err if err
                    realtimer.sendEnd "contacts.end"
                    callback null

        ], (err) ->
            log.debug "import from google complete"
            realtimer.sendEnd "ok"
            console.log err if err
