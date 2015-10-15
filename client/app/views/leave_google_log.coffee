BaseView = require '../lib/base_view'

module.exports = class LeaveGoogleLogView extends BaseView

    template: require './templates/leave_google_log'
    tagName: 'main'
    id: 'leave-google'

    model:
        photos:
            processing: true
            numberPhotos: 0
            numberAlbum: 0
            total: 0
            error: []
        contacts:
            processing: true
            number:0
            total: 0
        events:
            processing: true
            number:0
            total: 0
        syncedGmail: false


    initialize: ->
        window.sio.on "photos.album", (data) =>
            @model.photos.numberAlbum = data.number
            @render()
        window.sio.on "photos.err", (data) =>
            @model.photos.error.push data.url
            @render()
        window.sio.on "photos.photo", (data) =>
            @model.photos.numberPhotos = data.number
            @model.photos.total = data.total
            @render()
        window.sio.on "calendars", (data) =>
            @model.events.number = data.number
            @model.events.total = data.total
            @render()
        window.sio.on "contacts", (data) =>
            @model.contacts.number = data.number
            @model.contacts.total = data.total
            @render()
        window.sio.on "events.end", =>
            @model.events.processing = false
            @render()
        window.sio.on "contacts.end", =>
            @model.contacts.processing = false
            @render()
        window.sio.on "photos.end", =>
            @model.photos.processing = false
            @render()
        window.sio.on "syncGmail.end", =>
            @model.syncedGmail = true
            @render()

        window.sio.on 'invalid token', =>
            @model.invalidToken = true
            @render()
            @model.invalidToken = false

        window.sio.on 'ok', =>
            @model.events.processing = false
            @model.contacts.processing = false
            @model.photos.processing = false
            @render()


    afterRender: ->
        app.router.navigate '', trigger: false

    getRenderData: ->
        return @model

