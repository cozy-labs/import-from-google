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
    contact = {}

    full_name = gContact.title?.$t or '(empty name)'

    contact.fn = full_name
    # infortunately google do not give us first_name and last_name
    # but only full_name
    contact.n = "#{full_name};;;;" # name in vcard name string format

    contact.note = gContact.content?.$t or ''

    contact.datapoints = []
    for email in gContact['gd$email'] or []
        contact.datapoints.push
            name: "email"
            pref: email.primary or false
            value: email.address
            type: email.rel?.replace(PREFIX, '') or 'other'

    for phone in gContact['gd$phoneNumber'] or []
        contact.datapoints.push
            name: "tel"
            pref: phone.primary or false
            value: phone.uri?.replace('tel:', '')
            type: phone.rel?.replace(PREFIX, '') or 'other'

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
