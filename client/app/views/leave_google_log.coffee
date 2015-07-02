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
            console.log "photos.album", data.number
            @model.photos.numberAlbum = data.number
            @render()
        window.sio.on "photos.err", (data) =>
            console.log "photos.err", data.number
            console.log data
            @model.photos.error.push data.url
            @render()
        window.sio.on "photos.photo", (data) =>
            console.log "photos.photo", data.number
            @model.photos.numberPhotos = data.number
            @model.photos.total = data.total
            @render()
        window.sio.on "calendars", (data)=>
            console.log "calendars", data.number
            @model.events.number = data.number
            @model.events.total = data.total
            @render()
        window.sio.on "contacts", (data) =>
            console.log "contacts", data.number
            @model.contacts.number = data.number
            @model.contacts.total = data.total
            @render()
        window.sio.on "events.end", =>
            console.log "calendars done"
            @model.events.processing = false
            @render()
        window.sio.on "contacts.end", =>
            console.log "contacts done"
            @model.contacts.processing = false
            @render()
        window.sio.on "photos.end", =>
            console.log "photos done"
            @model.photos.processing = false
            @render()
        window.sio.on "syncGmail.end", =>
            console.log "syncGmail done"
            @model.syncedGmail = true
            @render()

        window.sio.on 'invalid token', =>
            console.log "invalid token"
            @model.invalidToken = true
            @render()
            @model.invalidToken = false

    afterRender: ->
        app.router.navigate '', trigger: false

    getRenderData: ->
        return @model

