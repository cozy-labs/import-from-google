cozydb = require 'cozydb'

module.exports = Photo = cozydb.getModel 'Photo',
    id           : String
    title        : String
    description  : String
    orientation  : Number
    binary       : (x) -> x
    _attachments : Object
    albumid      : String
    date         : String

