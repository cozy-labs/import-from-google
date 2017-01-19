async = require 'async'
google = require 'googleapis'
calendar = google.calendar 'v3'
log = require('printit')
    date: true
    prefix: 'utils:calendar'
Event = require '../models/event'
realtimer = require './realtimer'
localizationManager = require './localization_manager'

{oauth2Client} = require './google_access_token'

NotificationHelper = require 'cozy-notifications-helper'
notification = new NotificationHelper 'import-from-google'


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
            return next err if err
            calendarEvents = calendarEvents.concat result.items
            pageToken = result.nextPageToken
            next null

    # until there is no more pages
    , isFinished

    # and then
    , (err)->
        return callback err if err
        log.debug "cozy to create #{calendarEvents.length} events"
        callback null, calendarEvents


module.exports = (access_token, callback)->
    oauth2Client.setCredentials access_token: access_token

    calendar.calendarList.list auth: oauth2Client, (err, response) ->
        if err
            log.error err if err
            return callback new Error 'cant get calendar'

        totalNumber     = 0
        numberProcessed = 0
        allEvents        = []

        # concat all events. Needed to get the total number of events to import
        concatEvents = (calendarItem, next) ->
            fetchCalendar calendarItem.id, (err, gEvents) ->
                return next err if err

                allEvents = allEvents.concat gEvents
                next null

        async.eachSeries response.items, concatEvents, (err) ->
            return callback err if err

            async.eachSeries allEvents, (gEvent, next)->
                unless Event.validGoogleEvent gEvent
                    log.error "invalid event"
                    log.error gEvent

                    realtimer.sendCalendar
                        number: ++numberProcessed
                        total: allEvents.length
                    next null
                else
                    cozyEvent = Event.fromGoogleEvent gEvent
                    if gEvent.organizer?.displayName?
                        tag = "(Google) #{gEvent.organizer.displayName}"
                    else
                        tag = 'google calendar'
                    cozyEvent.tags = [ tag ]
                    log.debug "cozy create 1 event"
                    Event.createIfNotExist cozyEvent, (err) ->
                        return callback err if err
                        log.error err if err
                        realtimer.sendCalendar
                            number: ++numberProcessed
                            total: allEvents.length

                        setTimeout next, 100
            , (err)->
                return callback err if err

                log.info "create notification for events"
                _ = localizationManager.t
                notification.createOrUpdatePersistent \
                    "leave-google-calendar",
                    app: 'import-from-google'
                    text: _ 'notif_import_event', total: numberProcessed
                    resource:
                        app: 'calendar'
                        url: 'calendar/'
                callback()

