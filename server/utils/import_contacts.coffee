Contact = require '../models/contact'
CompareContacts = require '../utils/compare_contacts'
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


addContactToCozy = (gContact, cozyContacts, callback) ->
    log.debug "import 1 contact"
    fromGoogle = new Contact Contact.fromGoogleContact gContact

    name = fromGoogle.getName()
    log.debug "looking or #{name}"

    # look for same, take the first one
    fromCozy = null
    for cozyContact in cozyContacts
        if CompareContacts.isSamePerson cozyContact, fromGoogle
            fromCozy = cozyContact
            break

    endCb = (err, updatedContact) ->
        log.debug "updated #{name} err=#{err}"
        return callback err if err
        addContactPicture updatedContact, gContact, (err) ->
            log.debug "picture err #{err}"
            setTimeout callback, 100
        numberProcessed += 1
        realtimer.sendContacts
            number: numberProcessed
            total: total

    if fromCozy? #  merge
        log.debug "merging #{name}"
        toCreate = CompareContacts.mergeContacts fromCozy, fromGoogle
        toCreate.save endCb

    else # create
        fromGoogle.revision = new Date().toISOString()
        log.debug "creating #{name}"
        Contact.create fromGoogle, endCb


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
        headers:
            'Authorization': 'Bearer ' + access_token
            'GData-Version': '3.0'

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

    async.parallel
        # google: dummyListContacts
        google: listContacts
        cozy: Contact.all
    , (err, contacts) ->
        log.debug "got #{contacts?.google?.length} contacts"
        return callback err if err
        total = contacts.google?.length

        async.eachSeries contacts.google, (gContact, cb) ->
            addContactToCozy gContact, contacts.cozy, cb
        , (err)->
            return callback err if err
            console.log "create notification for contacts"
            notification.createOrUpdatePersistent "leave-google-contacts",
                app: 'leave-google'
                text: "Importation de #{total} contacts terminé"
                resource:
                    app: 'contacts'
                    url: 'contacts/'

            callback()



dummyListContacts = (cb) ->
  cb null, [{
        "category": [
          {
            "term": "http://schemas.google.com/contact/2008#contact",
            "scheme": "http://schemas.google.com/g/2005#kind"
          }
        ],
        "gd$organization": [
          {
            "gd$orgTitle": {
              "$t": "Chairman"
            },
            "gd$orgName": {
              "$t": "SuperCorp"
            },
            "rel": "http://schemas.google.com/g/2005#work"
          }
        ],
        "updated": {
          "$t": "2015-06-29T13:47:08.426Z"
        },
        "gContact$groupMembershipInfo": [
          {
            "deleted": "false",
            "href": "http://www.google.com/m8/feeds/groups/rogerdupondt%40gmail.com/base/6"
          },
          {
            "deleted": "false",
            "href": "http://www.google.com/m8/feeds/groups/rogerdupondt%40gmail.com/base/35248e438cdaf6e2"
          }
        ],
        "gd$name": {
          "gd$givenName": {
            "$t": "AAAgoogleFirst",
            "yomi": "prenomph"
          },
          "gd$fullName": {
            "$t": "Mr AAAgoogleFirst Middleone Middletwo von AAALast Jr"
          },
          "gd$familyName": {
            "$t": "von AAALast",
            "yomi": "nomph"
          },
          "gd$additionalName": {
            "$t": "Middleone Middletwo"
          },
          "gd$namePrefix": {
            "$t": "Mr"
          },
          "gd$nameSuffix": {
            "$t": "Jr"
          }
        },
        "gContact$relation": [
          {
            "$t": "Spouse",
            "rel": "spouse"
          },
          {
            "$t": "Child One",
            "rel": "child"
          },
          {
            "$t": "Mom",
            "rel": "mother"
          },
          {
            "$t": "Dad",
            "rel": "father"
          },
          {
            "$t": "Step-parent",
            "rel": "parent"
          },
          {
            "$t": "Big Bro",
            "rel": "brother"
          },
          {
            "$t": "Lil Sis",
            "rel": "sister"
          },
          {
            "$t": "Good Friend",
            "rel": "friend"
          },
          {
            "$t": "Some Relative",
            "rel": "relative"
          },
          {
            "$t": "Big Boss",
            "rel": "manager"
          },
          {
            "$t": "Personal Assistant",
            "rel": "assistant"
          },
          {
            "$t": "Referred By",
            "rel": "referred-by"
          },
          {
            "$t": "Partner",
            "rel": "partner"
          },
          {
            "$t": "Domestic Partner",
            "rel": "domestic-partner"
          },
          {
            "$t": "Custom",
            "label": "Arbitrary-string"
          }
        ],
        "title": {
          "$t": "Mr AAAgoogleFirst Middleone Middletwo von AAALast Jr"
        },
        "gContact$fileAs": {
          "$t": "machin"
        },
        "gd$structuredPostalAddress": [
          {
            "gd$formattedAddress": {
              "$t": "678 Plain Home Address\nAll one field 354\nBridgeport CT 06"
            },
            "gd$street": {
              "$t": "678 Plain Home Address\nAll one field 354\nBridgeport CT 06"
            },
            "rel": "http://schemas.google.com/g/2005#home"
          },
          {
            "gd$formattedAddress": {
              "$t": "80 Maple Road\nNorthville\nPOB 999\nDanbury, CT 06810\nUSA"
            },
            "gd$postcode": {
              "$t": "06810"
            },
            "gd$street": {
              "$t": "80 Maple Road\nNorthville\nPOB 999\nDanbury, CT"
            },
            "rel": "http://schemas.google.com/g/2005#work",
            "gd$country": {
              "$t": "USA",
              "code": "US"
            }
          },
          {
            "gd$country": {
              "$t": "USA"
            },
            "gd$formattedAddress": {
              "$t": "678 Elm Street\nApt 354\nBridgeport, CT 06834\nUSA"
            },
            "label": "Weekends",
            "gd$city": {
              "$t": "Bridgeport"
            },
            "gd$street": {
              "$t": "678 Elm Street\nApt 354\n"
            },
            "gd$region": {
              "$t": "CT"
            },
            "gd$postcode": {
              "$t": "06834"
            }
          }
        ],
        "gd$im": [
          {
            "protocol": "http://schemas.google.com/g/2005#AIM",
            "rel": "http://schemas.google.com/g/2005#other",
            "address": "AIM"
          },
          {
            "protocol": "http://schemas.google.com/g/2005#GOOGLE_TALK",
            "rel": "http://schemas.google.com/g/2005#other",
            "address": "gTalk"
          },
          {
            "protocol": "http://schemas.google.com/g/2005#YAHOO",
            "rel": "http://schemas.google.com/g/2005#other",
            "address": "Yahoo"
          },
          {
            "protocol": "http://schemas.google.com/g/2005#JABBER",
            "rel": "http://schemas.google.com/g/2005#other",
            "address": "Jabber"
          },
          {
            "protocol": "http://schemas.google.com/g/2005#MSN",
            "rel": "http://schemas.google.com/g/2005#other",
            "address": "MSN"
          },
          {
            "protocol": "http://schemas.google.com/g/2005#SKYPE",
            "rel": "http://schemas.google.com/g/2005#other",
            "address": "Skype"
          },
          {
            "protocol": "http://schemas.google.com/g/2005#QQ",
            "rel": "http://schemas.google.com/g/2005#other",
            "address": "QQ"
          },
          {
            "protocol": "http://schemas.google.com/g/2005#ICQ",
            "rel": "http://schemas.google.com/g/2005#other",
            "address": "ICQ"
          }
        ],
        "gContact$nickname": {
          "$t": "john michael"
        },
        "content": {
          "$t": "Blah, blah\n\nblah blah blah.\n\nblahblah\nCustom: Custom field data"
        },
        "link": [
          {
            "href": "https://www.google.com/m8/feeds/photos/media/rogerdupondt%40gmail.com/35634daa896f7801",
            "type": "image/*",
            "rel": "http://schemas.google.com/contacts/2008/rel#photo"
          },
          {
            "href": "https://www.google.com/m8/feeds/contacts/rogerdupondt%40gmail.com/full/35634daa896f7801",
            "type": "application/atom+xml",
            "rel": "self"
          },
          {
            "href": "https://www.google.com/m8/feeds/contacts/rogerdupondt%40gmail.com/full/35634daa896f7801",
            "type": "application/atom+xml",
            "rel": "edit"
          }
        ],
        "gd$email": [
          {
            "primary": "true",
            "rel": "http://schemas.google.com/g/2005#home",
            "address": "homeEmail@example.com"
          },
          {
            "rel": "http://schemas.google.com/g/2005#work",
            "address": "workEmail@example.com"
          },
          {
            "label": "Arbitrary String",
            "address": "customEmail@example.com"
          }
        ],
        "gContact$website": [
          {
            "href": "http://profile.example.com/",
            "rel": "profile"
          },
          {
            "href": "http://blog.example.com/",
            "rel": "blog"
          },
          {
            "href": "http://home.example.com/",
            "rel": "home-page"
          },
          {
            "href": "http://work.example.com/",
            "rel": "work"
          },
          {
            "href": "http://custom.example.com/",
            "label": "arbitraryString"
          }
        ],
        "gd$etag": "\"SXo5fjVSLit7I2A9XRVWFUUPQQY.\"",
        "gd$phoneNumber": [
          {
            "$t": "+1 860 355 3887",
            "uri": "tel:+1-860-355-3887",
            "rel": "http://schemas.google.com/g/2005#home"
          },
          {
            "$t": "+1 860 350 0301",
            "uri": "tel:+1-860-350-0301",
            "rel": "http://schemas.google.com/g/2005#work"
          },
          {
            "$t": "+1 203 207 1047",
            "uri": "tel:+1-203-207-1047",
            "rel": "http://schemas.google.com/g/2005#mobile"
          },
          {
            "$t": "+1 212 555 1234",
            "uri": "tel:+1-212-555-1234",
            "rel": "http://schemas.google.com/g/2005#main"
          },
          {
            "$t": "+1 212 555 2345",
            "uri": "tel:+1-212-555-2345",
            "rel": "http://schemas.google.com/g/2005#work_fax"
          },
          {
            "$t": "+1 212 555 3456",
            "uri": "tel:+1-212-555-3456",
            "rel": "http://schemas.google.com/g/2005#home_fax"
          },
          {
            "$t": "+1 212 555 4567",
            "uri": "tel:+1-212-555-4567",
            "label": "GRAND_CENTRAL"
          },
          {
            "$t": "+1 212 555 0000",
            "uri": "tel:+1-212-555-0000",
            "rel": "http://schemas.google.com/g/2005#pager"
          }
        ],
        "app$edited": {
          "xmlns$app": "http://www.w3.org/2007/app",
          "$t": "2015-06-29T13:47:08.426Z"
        },
        "gContact$event": [
          {
            "gd$when": {
              "startTime": "2014-12-31"
            },
            "label": "Died"
          },
          {
            "gd$when": {
              "startTime": "2001-01-01"
            },
            "rel": "anniversary"
          }
        ],
        "id": {
          "$t": "http://www.google.com/m8/feeds/contacts/rogerdupondt%40gmail.com/base/35634daa896f7801"
        },
        "gContact$birthday": {
          "when": "1961-04-05"
        }
      }
  ]

