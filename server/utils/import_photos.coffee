request = require 'request-json'
async = require 'async'
https = require 'https'
im = require 'imagemagick-stream'
pass = require('stream').PassThrough
log = require('printit')(prefix: 'photosimport')

gdataClient = require('gdata-js')("useless", "useless", 'http://localhost/')

realtimer = require './realtimer'

Album = require '../models/album'
Photo = require '../models/photo'
i = 0

NotificationHelper = require 'cozy-notifications-helper'
notification = new NotificationHelper 'leave-google'
localizationManager = require './localization_manager'


#errUrl is an array with url of photos not saved
errUrl = []

addUrlErr = (url)->
    if errUrl.indexOf(url) > -1
        errUrl.push url

PICASSA_URL = "https://picasaweb.google.com/data/feed/api/"
ALBUMS_URL = "#{PICASSA_URL}user/default"
numberPhotosProcessed = 0
total = 0


getTotal = (albums, callback) ->
    async.eachSeries albums, (gAlbum, next) ->
        albumFeedUrl = "#{ALBUMS_URL}/albumid/#{gAlbum.gphoto$id.$t}?alt=json"
        log.debug albumFeedUrl
        log.debug "get photos total (album length to add to total)"
        gdataClient.getFeed albumFeedUrl, (err, photos) ->
            next err if err
            total += if photos then photos.feed.entry.length else 0
            log.debug "photo total: #{total}"
            next()
    , callback

importAlbum = (gAlbum, done) ->
    albumToCreate =
        title: gAlbum.title.$t
        description: "Imported from your google account"

    log.debug "creating album #{gAlbum.title.$t}"
    Album.createIfNotExist albumToCreate, (err, cozyAlbum) ->
        log.debug "created #{err}"

        importPhotos cozyAlbum.id, gAlbum, done

importPhotos = (cozyAlbumId, gAlbum, done) ->
    albumFeedUrl = "#{ALBUMS_URL}/albumid/#{gAlbum.gphoto$id.$t}?alt=json"
    log.debug "get photos list"
    gdataClient.getFeed albumFeedUrl, (err, photos) ->
        log.debug "got photos list err=#{err}"
        return done err if err
        photos = photos.feed.entry or []

        async.eachSeries photos, (gPhoto, next) ->
            importOnePhoto cozyAlbumId, gPhoto, (err) ->
                log.debug "done with 1 photo"
                log.error err if err
                realtimer.sendPhotosPhoto
                    number: ++numberPhotosProcessed
                    total: total
                next null # loop anyway
        , done

importOnePhoto = (albumId, photo, done)->
    url = photo.content.src
    type = photo.content.type
    name = photo.title.$t
    if type is "image/gif" # we don't handle gif
        return done()

    data =
        title: name
        albumid: albumId

    log.debug "creating photo #{data.title}"
    Photo.createIfNotExist data, (err, cozyPhoto)->
        if cozyPhoto.exist
            return done()
        downloadOnePhoto cozyPhoto, url, type, done

downloadOnePhoto = (cozyPhoto, url, type, done) ->
    https.get url, (stream)->
        stream.on 'error', done
        resizeThumb = im().resize('300x300^').crop('300x300')
        resizeScreen = im().resize('1200x800')

        # this is a tips to duplicate a stream
        # we give a highWaterMark of 16MB because the stream
        # must be able to store a full picture file
        raw = new pass highWaterMark: 16*1000*1000
        thumb = new pass highWaterMark: 16*1000*1000
        screen = new pass highWaterMark: 16*1000*1000
        stream.pipe(thumb)
        stream.pipe(screen)
        stream.pipe(raw)

        attach = (which, stream, cb) ->
            # the actual name is set by name property, but request is weird
            # @TODO : may be we can remove this with cozydb
            stream.path = 'useless'
            cozyPhoto.attachBinary stream, {name: which, type: type}, (err)->
                if err
                    addUrlErr url
                    log.error "#{which} #{err}"
                else
                    log.debug "#{which} ok"
                cb err

        async.series [
            (cb) ->
                attach 'raw', raw, cb
            (cb)->
                thumbStream = thumb.pipe(resizeThumb)
                attach 'thumb', thumbStream, cb
            (cb)->
                screenStream = screen.pipe(resizeScreen)
                attach 'screen', screenStream, cb
        ], done


module.exports = (access_token, done)->
    gdataClient.setToken access_token: access_token

    log.debug "get album list"
    gdataClient.getFeed ALBUMS_URL, (err, feed) ->
        log.debug "got list err=#{err}"
        numberAlbumProcessed = 0
        numberPhotosProcessed = 0
        total = 0
        getTotal feed.feed.entry, ->
            async.eachSeries feed.feed.entry, (gAlbum, next) ->
                importAlbum gAlbum, (err) ->
                    log.debug "done with 1 album"
                    log.error err if err
                    realtimer.sendPhotosAlbum number: ++numberAlbumProcessed
                    next null # loop anyway
            , (err)->
                return done err if err

                notification.createOrUpdatePersistent "leave-google-photos",
                    app: 'leave-google'
                    text: localizationManager.t 'notif_import_photo', total: numberPhotosProcessed
                    resource:
                        app: 'photos'
                        url: 'photos/'
                done()
