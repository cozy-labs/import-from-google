cozydb = require 'cozydb'
momentTz = require 'moment-timezone'
async = require 'async'
log = require('printit')
    date: true
    prefix: 'model:event'
_ = require 'lodash'

module.exports = Event = cozydb.getModel 'Event',
    start       : type: String
    end         : type: String
    place       : type: String
    details     : type: String
    description : type: String
    rrule       : type: String
    tags        : [String]
    attendees   : type: [Object]
    related     : type: String, default: null
    timezone    : type: String
    alarms      : type: [Object]
    created     : type: String
    lastModification: type: String

# 'start' and 'end' use those format,
# According to allDay or rrules.
Event.dateFormat = 'YYYY-MM-DD'
Event.ambiguousDTFormat = 'YYYY-MM-DD[T]HH:mm:00.000'
Event.utcDTFormat = 'YYYY-MM-DD[T]HH:mm:00.000[Z]'

# Handle only unique units strings.
Event.alarmTriggRegex = /(\+?|-)PT?(\d+)(W|D|H|M|S)/

convertISO = (dateTimeTimezoned)->
    return false unless dateTimeTimezoned
    try
        res = new Date(dateTimeTimezoned).toISOString()
    catch err
        log.error err
        log.error dateTimeTimezoned
        res = false
    return res

Event.fromGoogleEvent = (gEvent) ->
    data =
        start: convertISO(gEvent.start.dateTime) || gEvent.start.date
        end: convertISO(gEvent.end.dateTime) || gEvent.end.date
        timezone: gEvent.start.timezone || gEvent.end.timezone
        place: gEvent.location
        details: gEvent.description
        description: gEvent.summary

    if gEvent.recurrence
        data.rrule = gEvent.recurrence[0].substring("RRULE:".length)

    return data

Event.validGoogleEvent = (gEvent) ->
    return valid = (gEvent.start?.dateTime? or gEvent.start?.date?) and
        (gEvent.end?.dateTime? or gEvent.end?.date?) and
        gEvent.summary?


Event.createIfNotExist = (cozyEvent, callback) ->
    Event.request 'byDate', key: cozyEvent.start, (err, events) ->
        return callback err if err?
        exist = _.find events, (event)->
            return event.end is cozyEvent.end and
               event.description is cozyEvent.description
        if exist
            log.info "event starting on #{cozyEvent.start} already exist"
            callback()
        else
            log.info "create event starting on #{cozyEvent.start}"
            Event.create cozyEvent, callback





