cozydb = require 'cozydb'
log = require('printit')
    date: true
    prefix: 'model:photos'

module.exports = Photo = cozydb.getModel 'Photo',
    id           : String
    title        : String
    description  : String
    orientation  : Number
    binary       : (x) -> x
    _attachments : Object
    albumid      : String
    date         : String

Photo.createIfNotExist = (photo, callback)->
    Photo.request 'byTitle', key: photo.title, (err, photos)->
        return callback err if err?
        log.debug "#{photo.title} check if exist"

        if photos.length > 0
            exist = photos[0]

        log.debug "exist ? #{exist}"

        if exist?
            log.info "#{photo.title} already imported"
            exist.exist = true
            callback null, exist
        else
            log.info "importing #{photo.title}"
            Photo.create photo, callback

