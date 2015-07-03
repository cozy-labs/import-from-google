# See documentation on https://github.com/cozy/cozy-db

cozydb = require 'cozydb'
emit = null # coffee-jshint doesnt know couchdb

module.exports =
    contact:
        all: cozydb.defaultRequests.all
        byName: (doc) ->
            if doc.fn? and doc.fn.length > 0
                emit doc.fn, doc
            else if doc.n?
                emit doc.n.split(';').join(' ').trim(), doc
            else
                for dp in doc.datapoints
                    if dp.name is 'email'
                        emit dp.value, doc
    event:
        all: cozydb.defaultRequests.all
        byDate: (doc) -> emit new Date(doc.start), doc
        byCalendar: cozydb.defaultRequests.by 'tags[0]'
    account:
        all: cozydb.defaultRequests.all
        byEmailWithOauth: (doc) ->
            if doc.oauthProvider is "GMAIL"
                emit doc.login, doc
    photo:
        byTitle: (doc) -> emit doc.title, doc
    album:
        byTitle: (doc) -> emit doc.title, doc
