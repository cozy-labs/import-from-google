cozydb = require 'cozydb'
async = require 'async'
fs = require 'fs'
log = require('printit')
    prefix: 'Contact Model'


# Datapoints is an array of { name, type, value ...} objects,
# values are typically String. Particular case, adr :
# name: 'adr',
# type: 'home',
# value: ['','', '12, rue Basse', 'Paris','','75011', 'France']
class DataPoint extends cozydb.Model
    @schema:
        name: String
        value: cozydb.NoSchema
        pref: Boolean
        type: String


module.exports = class Contact extends cozydb.CozyModel
    @docType: 'contact'
    @schema:
        id            : String
        # vCard FullName = display name
        # (Prefix Given Middle Familly Suffix), or something else.
        fn            : String
        # vCard Name = splitted
        # (Familly;Given;Middle;Prefix;Suffix)
        n             : String
        org           : String
        title         : String
        department    : String
        bday          : String
        nickname      : String
        url           : String
        revision      : Date
        datapoints    : [DataPoint]
        note          : String
        tags          : [String]
        binary        : Object
        _attachments  : Object

    @cast: (attributes, target) ->
        target = super attributes, target

        return target

# Update revision each time a change occurs
Contact::updateAttributes = (changes, callback) ->
    changes.revision = new Date().toISOString()
    super


# Update revision each time a change occurs
Contact::save = (callback) ->
    @revision = new Date().toISOString()
    super


PREFIX = 'http://schemas.google.com/g/2005#'

Contact.fromGoogleContact = (gContact)->
    return unless gContact?

    contact =

        fn: gContact.gd$name?.gd$fullName
        n: "#{gContact.gd$name?.gd$familyName?.$t or ''};#{gContact.gd$name?.gd$givenName?.$t or ''};#{gContact.gd$name?.gd$additionalName?.$t or ''};#{gContact.gd$name?.gd$namePrefix?.$t or ''};#{gContact.gd$name?.gd$nameSuffix?.$t or ''}"

        org: gContact?.gd$organization?.gd$orgName?.$t
        title: gContact?.gd$organization?.gd$orgTitle?.$t
        # department
        bday: gContact.gContact$birthday?.when
        nickname: gContact.gContact$nickname?.$t
        note: gContact.content?.$t

        # url:   ?many...
        # revision      : <-- todo ?
        #tags          : ['google']
        #accounts
        #??binary        : Object

        #  SOCIAL.
    getTypeFragment = (component) ->
        return component.rel?.split('#')[1] or component.label or 'other'
    getTypePlain = (component) ->
        return component.rel or component.label or 'other'


    contact.datapoints = []
    for email in gContact.gd$email or []
        contact.datapoints.push
            name: "email"
            pref: email.primary or false
            value: email.address
            type: getTypeFragment email


    for phone in gContact.gd$phoneNumber or []
        contact.datapoints.push
            name: "tel"
            pref: phone.primary or false
            value: phone.uri?.replace('tel:', '')
            type: getTypeFragment phone

    for im in gContact.gd$im or []
        contact.datapoints.push
            name: "chat"
            value: im.address
            type: im.protocol?.split('#')[1] or 'other'

    for adr in gContact.gd$structuredPostalAddress or []
        contact.datapoints.push
            name: "adr"
            value: adr.gd$formattedAddress?.$t
            type: getTypeFragment adr


    for web in gContact.gContact$website or []
        contact.datapoints.push
            name: "url"
            value: web.href
            type: getTypePlain web

    for rel in gContact.gContact$relation or []
        contact.datapoints.push
            name: "relation"
            value: rel.$t
            type: getTypePlain rel

    for ev in gContact.gContact$event or []
        contact.datapoints.push
            name: "about"
            value: ev.gd$when?.startTime
            type: getTypePlain ev

    return contact

Contact::getName = ->
    # Checks first if the contact doesn't
    # exist already by comparing the names
    # or emails if name is not specified.
    name = ''
    if @fn? and @fn.length > 0
        name = @fn
    else if @n and @n.length > 0
        name = @n.split(';').join(' ').trim()
    else
        for dp in @datapoints
            if dp.name is 'email'
                name = dp.value

    return name
