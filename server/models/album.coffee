cozydb = require 'cozydb'

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
