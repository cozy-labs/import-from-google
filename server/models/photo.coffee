cozydb = require 'cozydb'
_ = require 'lodash'
log = require('printit')(prefix: 'photomodel')


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
        exist = _.find photos, (fetchedPhoto)->
            return photo.albumid is fetchedPhoto.albumid
        if exist
            log.debug "#{photo.title} already imported"
            exist.exist = true
            callback null, exist
        else
            Photo.create photo, callback

