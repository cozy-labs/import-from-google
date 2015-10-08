cozydb = require 'cozydb'
_ = require 'lodash'
log = require('printit')('modelAlbum')

module.exports = Album = cozydb.getModel 'Album',
    id            : String
    title         : String
    description   : String
    date          : Date
    orientation   : Number
    coverPicture  : String
    clearance: (x) -> x
    folderid      : String

Album.beforeSave = (data, callback) ->
    if data.title?
        data.title = data.title
                        .replace /<br>/g, ""
                        .replace /<div>/g, ""
                        .replace /<\/div>/g, ""

    # Set default date if not set.
    data.date = new Date()

    callback()


Album.createIfNotExist = (album, callback)->
    Album.request 'byTitle', key: album.title, (err, albums)->
        log.debug "#{album.title} check if exist"
        exist = _.find albums, (fetchedAlbum)->
            return album.description is fetchedAlbum.description

        log.debug "exist ? #{exist}"

        if exist
            log.debug "#{album.title} already imported"
            callback null, exist
        else
            Album.create album, callback

