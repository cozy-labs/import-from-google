async = require 'async'
realtimer = require './realtimer'
log = require('printit')(prefix: 'contactsimport')
_ = require 'lodash'
https = require('https')
url = require 'url'

Contact = require '../models/contact'
Tag = require '../models/tag'
CompareContacts = require '../utils/compare_contacts'
GoogleContactHelper = require '../utils/google_contact_helper'
NotificationHelper = require 'cozy-notifications-helper'
notification = new NotificationHelper 'import-from-google'
localizationManager = require './localization_manager'


listContacts = (token, callback) ->
    opts =
        host: 'www.google.com'
        port: 443
        path: '/m8/feeds/contacts/default/full?alt=json&max-results=10000'
        method: 'GET'
        headers:
            'Authorization': 'Bearer ' + token
            'GData-Version': '3.0'

    req = https.request opts, (res) ->
        data = []

        res.on 'error', callback
        res.on 'data', (chunk) -> data.push chunk
        res.on 'end', ->
            err = null
            result = null
            if res.statusCode is 200
                try
                    result = JSON.parse(data.join('')).feed.entry
                catch e
                    err = e
            else
                err = new Error("Error #{res.statusCode}")

            callback err, result

    req.on 'error', callback
    req.end()


# get a list of every contact of a google account
module.exports = (token, callback) ->
    log.debug 'request contacts list'
    async.parallel
        google: (cb) -> listContacts token, cb
        cozyContacts: Contact.all
        accountName: (cb) -> GoogleContactHelper.fetchAccountName token, cb
        # Create a tag with google's blue to put on each synchronized contact.
        tag: (cb) -> Tag.getOrCreate { name: 'google', color: '#4285F4'}, cb
    , (err, contacts) ->
        log.debug "got #{contacts?.google?.length} contacts"
        return callback err if err

        contacts.ofAccountByIds = GoogleContactHelper
            .filterContactsOfAccountByIds contacts.cozyContacts
            , contacts.accountName

        numberProcessed = 0
        total = contacts.google?.length
        async.eachSeries contacts.google, (gContact, cb) ->
            GoogleContactHelper.updateCozyContact gContact, contacts
            , contacts.accountName, token, (err, updatedContact)->
                numberProcessed += 1
                realtimer.sendContacts
                    number: numberProcessed
                    total: total

                # Throttle the async loop to prevent performance burst.
                setTimeout -> cb err
                , 1
        , (err)->
            return callback err if err
            _ = localizationManager.t
            notification.createOrUpdatePersistent "leave-google-contacts",
                app: 'import-from-google'
                text: _ 'notif_import_contact', total: total
                resource:
                    app: 'contacts'
                    url: 'contacts/'
            callback()
