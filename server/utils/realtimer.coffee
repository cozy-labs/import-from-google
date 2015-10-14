_ = require 'lodash'

socket = null

sendCalendar = _.throttle((data) ->
    return unless socket
    socket.emit 'calendars', data
, 350)
sendCalendarErr = _.throttle((data) ->
    return unless socket
    socket.emit 'photos.err', data
, 350)
sendPhotosPhoto = _.throttle((data) ->
    return unless socket
    socket.emit 'photos.photo', data
, 350)
sendPhotosErr = _.throttle((data) ->
    return unless socket
    socket.emit 'photos.err', data
, 350)
sendPhotosAlbum = _.throttle((data) ->
    return unless socket
    socket.emit 'photos.album', data
, 350)
sendContacts = _.throttle((data) ->
    return unless socket
    socket.emit 'contacts', data
, 350)
sendContactsErr = _.throttle((data) ->
    return unless socket
    socket.emit 'photos.err', data
, 350)

sendEnd = (message) ->
    return unless socket
    socket.emit message

module.exports.sendCalendar    = sendCalendar
module.exports.sendCalendarErr = sendCalendarErr
module.exports.sendPhotosPhoto = sendPhotosPhoto
module.exports.sendPhotosErr   = sendPhotosErr
module.exports.sendPhotosAlbum = sendPhotosAlbum
module.exports.sendContacts    = sendContacts
module.exports.sendContactsErr = sendContactsErr
module.exports.sendEnd         = sendEnd

module.exports.set = (s) ->
    socket = s
