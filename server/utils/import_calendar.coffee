async = require 'async'
google = require 'googleapis'
calendar = google.calendar 'v3'
_ = require 'lodash'
log = require('printit')(prefix: 'calendarimport')
Event = require '../models/event'
realtimer = require './realtimer'

_ = require 'lodash'

{oauth2Client} = require './google_access_token'

NotificationHelper = require 'cozy-notifications-helper'
notification = new NotificationHelper 'leave-google'


getCalendarId = (callback) ->
    calendar.calendarList.list auth: oauth2Client, (err, response) ->
        return callback err if err
        found = null
        for calendarItem in response.items
            if calendarItem.primary
                found = calendarItem.id

        # no primary calendar ... pick first
        found ?= response.items?[0]?.id
        callback null, found

fetchOnePage =  (calendarId, pageToken, callback)->
    params =
        userId: 'me'
        auth: oauth2Client
        calendarId: calendarId

    if pageToken isnt "nopagetoken"
        params.pageToken = pageToken

    log.debug 'requesting more events'
    calendar.events.list params, (err, result)->
        if err
            log.debug "error #{err}"
            callback err
        else
            log.debug "got #{result.items.length} events"
            callback null, result

fetchCalendar = (calendarId, callback) ->
    calendarEvents = []
    numberProcessed = 0
    pageToken = "nopagetoken"

    isFinished = -> pageToken? and pageToken isnt "nopagetoken"

    # fetch page by page
    async.doWhilst (next) ->
        fetchOnePage calendarId, pageToken, (err, result) ->
            calendarEvents = calendarEvents.concat result.items
            pageToken = result.nextPageToken
            next null

    # until there is no more pages
    , isFinished

    # and then
    , (err)->
        return callback err if err
        log.debug "cozy to create #{calendarEvents.length} event"
        callback null, calendarEvents


module.exports = (access_token, callback)->
    oauth2Client.setCredentials access_token: access_token

    getCalendarId (err, calendarId) ->
        if err or not calendarId
            log.error err if err
            return callback new Error 'cant get primary calendar'

        # @TODO fetch other calendars ?
        fetchCalendar calendarId, (err, gEvents) ->
            return callback err if err

            numberProcessed = 0
            async.eachSeries gEvents, (gEvent, next)->
                return next null unless Event.validGoogleEvent gEvent
                # it's not an error
                cozyEvent = Event.fromGoogleEvent gEvent
                cozyEvent.tags = ['google calendar']
                log.debug "cozy create 1 event"
                Event.createIfNotExist cozyEvent, (err) ->
                    return callback err if err
                    log.error err if err
                    setTimeout next, 100
                    realtimer.sendCalendar
                        number: ++numberProcessed
                        total: gEvents.length
            , (err)->
                return callback err if err

                log.info "create notification for events"
                notification.createOrUpdatePersistent "leave-google-calendar",
                    app: 'leave-google'
                    text: "Importation de #{numberProcessed} évenements terminé"
                    resource:
                        app: 'calendar'
                        url: 'calendar/'
                callback()



