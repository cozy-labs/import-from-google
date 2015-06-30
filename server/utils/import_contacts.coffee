Contact = require '../models/contact'
async = require 'async'
realtimer = require './realtimer'
log = require('printit')(prefix: 'contactsimport')
im = require('imagemagick-stream')
_ = require 'lodash'
https = require('https')
url = require 'url'

access_token = null

numberProcessed = 0
total = 0

NotificationHelper = require 'cozy-notifications-helper'
notification = new NotificationHelper 'leave-google'


createContact = (gContact, callback) ->
    log.debug "import 1 contact"
    toCreate = new Contact Contact.fromGoogleContact gContact

    name = toCreate.getName()
    log.debug "looking or #{name}"
    Contact.request 'byName', key: name, (err, contacts) ->
        if err
            numberProcessed += 1
            realtimer.sendContacts
                number: numberProcessed
                total: contact
            log.debug "err #{err}"
            callback null
        else if contacts.length is 0
            toCreate.revision = new Date().toISOString()
            log.debug "creating #{name}"
            Contact.create toCreate, (err, created) ->
                log.debug "created #{name} err=#{err}"
                return callback err if err
                addContactPicture created, gContact, (err) ->
                    log.debug "picture err #{err}"
                    setTimeout callback, 100
            numberProcessed += 1
            realtimer.sendContacts
                number: numberProcessed
                total: total
        else
            numberProcessed += 1
            realtimer.sendContacts
                number: numberProcessed
                total: total
            log.debug "existing #{name}"
            callback null

PICTUREREL = "http://schemas.google.com/contacts/2008/rel#photo"
addContactPicture = (cozyContact, gContact, done) ->
    pictureLink = gContact.link.filter (link) -> link.rel is PICTUREREL
    pictureUrl = pictureLink[0]?.href

    return done null unless pictureUrl

    opts = url.parse(pictureUrl)
    opts.headers = 'Authorization': 'Bearer ' + access_token

    https.get opts, (stream)->
        stream.on 'error', done
        unless stream.statusCode is 200
            log.warn "error fetching #{pictureUrl}", stream.statusCode
            return done null
        thumbStream = stream.pipe im().resize('300x300^').crop('300x300')
        thumbStream.on 'error', done
        thumbStream.path = 'useless'
        type = stream.headers['content-type']
        opts = {name: 'picture', type: type}
        cozyContact.attachFile thumbStream, opts, (err)->
            if err
                log.error "picture #{err}"
            else
                log.debug "picture ok"
            done err


listContacts = (callback) ->

    opts =
        host: 'www.google.com'
        port: 443
        path: '/m8/feeds/contacts/default/full?alt=json&max-results=10000'
        method: 'GET'
        headers: 'Authorization': 'Bearer ' + access_token

    req = https.request opts, (res) ->
        data = []

        res.on 'error', callback
        res.on 'data', (chunk) -> data.push chunk
        res.on 'end', ->
            if res.statusCode is 200
                try
                    result = JSON.parse data.join('')
                    callback null, result.feed.entry
                catch err then callback err
            else
                callback new Error("Error #{res.statusCode}")


    req.on 'error', callback
    req.end()

# get a list of every contact of a google account
module.exports = (token, callback) ->
    access_token = token
    log.debug 'request contacts list'
    numberProcessed = 0
    listContacts (err, contacts)->
        return callback err if err
        log.debug "got #{contacts.length} contacts"
        total = contacts.length
        async.eachSeries contacts, createContact, (err)->
            callback err if err
            console.log "create notification for contacts"
            notification.createOrUpdatePersistent "leave-google-contacts",
                app: 'leave-google'
                text: "Importation de #{total} contacts terminé"
                resource:
                    app: 'contacts'
                    url: 'contacts/'
            callback()
