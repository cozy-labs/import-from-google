// Generated by CoffeeScript 1.9.0
var sendCalendar, sendCalendarErr, sendContacts, sendContactsErr, sendEnd, sendPhotosAlbum, sendPhotosErr, sendPhotosPhoto, socket, _;

_ = require('lodash');

socket = null;

sendCalendar = _.throttle(function(data) {
  if (!socket) {
    return;
  }
  return socket.emit('calendars', data);
}, 350);

sendCalendarErr = _.throttle(function(data) {
  if (!socket) {
    return;
  }
  return socket.emit('photos.err', data);
}, 350);

sendPhotosPhoto = _.throttle(function(data) {
  if (!socket) {
    return;
  }
  return socket.emit('photos.photo', data);
}, 350);

sendPhotosErr = _.throttle(function(data) {
  if (!socket) {
    return;
  }
  return socket.emit('photos.err', data);
}, 350);

sendPhotosAlbum = _.throttle(function(data) {
  if (!socket) {
    return;
  }
  return socket.emit('photos.album', data);
}, 350);

sendContacts = _.throttle(function(data) {
  if (!socket) {
    return;
  }
  return socket.emit('contacts', data);
}, 350);

sendContactsErr = _.throttle(function(data) {
  if (!socket) {
    return;
  }
  return socket.emit('photos.err', data);
}, 350);

sendEnd = function(message) {
  if (!socket) {
    return;
  }
  return socket.emit(message);
};

module.exports.sendCalendar = sendCalendar;

module.exports.sendCalendarErr = sendCalendarErr;

module.exports.sendPhotosPhoto = sendPhotosPhoto;

module.exports.sendPhotosErr = sendPhotosErr;

module.exports.sendPhotosAlbum = sendPhotosAlbum;

module.exports.sendContacts = sendContacts;

module.exports.sendContactsErr = sendContactsErr;

module.exports.sendEnd = sendEnd;

module.exports.set = function(s) {
  return socket = s;
};
