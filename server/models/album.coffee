cozydb = require 'cozydb'
_ = require 'lodash'

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
        exist = _.find albums, (fetchedAlbum)->
            return album.description is fetchedAlbum.description
        if exist
            callback null, exist
        else
            Album.create album, callback

