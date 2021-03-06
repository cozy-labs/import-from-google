// Generated by CoffeeScript 1.9.3
var ALBUMS_URL, Album, NotificationHelper, PICASSA_URL, Photo, addUrlErr, async, downloadOnePhoto, errUrl, gdataClient, getTotal, https, i, im, importAlbum, importOnePhoto, importPhotos, localizationManager, log, notification, numberPhotosProcessed, pass, realtimer, total;

async = require('async');

https = require('https');

im = require('imagemagick-stream');

pass = require('stream').PassThrough;

log = require('printit')({
  date: true,
  prefix: 'utils:photos'
});

gdataClient = require('gdata-js')("useless", "useless", 'http://localhost/');

realtimer = require('./realtimer');

Album = require('../models/album');

Photo = require('../models/photo');

i = 0;

NotificationHelper = require('cozy-notifications-helper');

notification = new NotificationHelper('import-from-google');

localizationManager = require('./localization_manager');

errUrl = [];

addUrlErr = function(url) {
  if (errUrl.indexOf(url) > -1) {
    return errUrl.push(url);
  }
};

PICASSA_URL = "https://picasaweb.google.com/data/feed/api/";

ALBUMS_URL = PICASSA_URL + "user/default";

numberPhotosProcessed = 0;

total = 0;

getTotal = function(albums, callback) {
  return async.eachSeries(albums, function(gAlbum, next) {
    var albumFeedUrl;
    albumFeedUrl = ALBUMS_URL + "/albumid/" + gAlbum.gphoto$id.$t + "?alt=json";
    log.debug(albumFeedUrl);
    log.debug("get photos total (album length to add to total)");
    return gdataClient.getFeed(albumFeedUrl, function(err, photos) {
      var ref;
      if (err) {
        log.error(err);
        return next(err);
      } else {
        if ((photos != null ? (ref = photos.feed) != null ? ref.entry : void 0 : void 0) != null) {
          total += photos.feed.entry.length;
        } else {
          total += 0;
        }
        log.debug("photo total: " + total);
        return next();
      }
    });
  }, callback);
};

importAlbum = function(gAlbum, done) {
  var albumToCreate;
  albumToCreate = {
    title: gAlbum.title.$t,
    description: "Imported from your google account"
  };
  log.debug("creating album " + gAlbum.title.$t);
  return Album.createIfNotExist(albumToCreate, function(err, cozyAlbum) {
    if (err) {
      log.error(err);
      return done(err);
    } else {
      log.debug("created " + err);
      return importPhotos(cozyAlbum.id, gAlbum, done);
    }
  });
};

importPhotos = function(cozyAlbumId, gAlbum, done) {
  var albumFeedUrl;
  albumFeedUrl = ALBUMS_URL + "/albumid/" + gAlbum.gphoto$id.$t + "?alt=json";
  log.debug("get photos list");
  return gdataClient.getFeed(albumFeedUrl, function(err, photos) {
    log.debug("got photos list err=" + err);
    if (err) {
      return done(err);
    }
    photos = photos.feed.entry || [];
    return async.eachSeries(photos, function(gPhoto, next) {
      return importOnePhoto(cozyAlbumId, gPhoto, function(err) {
        if (err) {
          log.error(err);
        } else {
          log.debug("done with 1 photo");
        }
        realtimer.sendPhotosPhoto({
          number: ++numberPhotosProcessed,
          total: total
        });
        return next(null);
      });
    }, done);
  });
};

importOnePhoto = function(albumId, photo, done) {
  var data, name, type, url;
  url = photo.content.src;
  type = photo.content.type;
  name = photo.title.$t;
  if (type === "image/gif") {
    return done();
  }
  data = {
    title: name,
    albumid: albumId
  };
  log.debug("creating photo " + data.title);
  return Photo.createIfNotExist(data, function(err, cozyPhoto) {
    if (err) {
      log.error(err);
      return done(err);
    } else {
      if (cozyPhoto.exist) {
        return done();
      }
      return downloadOnePhoto(cozyPhoto, url, type, done);
    }
  });
};

downloadOnePhoto = function(cozyPhoto, url, type, done) {
  return https.get(url, function(stream) {
    var attach, raw, resizeScreen, resizeThumb, screen, thumb;
    stream.on('error', done);
    resizeThumb = im().resize('300x300^').crop('300x300');
    resizeScreen = im().resize('1200x800');
    raw = new pass({
      highWaterMark: 16 * 1000 * 1000
    });
    thumb = new pass({
      highWaterMark: 16 * 1000 * 1000
    });
    screen = new pass({
      highWaterMark: 16 * 1000 * 1000
    });
    stream.pipe(thumb);
    stream.pipe(screen);
    stream.pipe(raw);
    attach = function(which, stream, cb) {

      /* This is a huge hack to not setHeader if length
          is null, this is caused by streaming resize
          Check after cozydb update
       */
      var opts, request;
      stream.fd = true;
      opts = {
        name: which,
        type: type
      };
      request = cozyPhoto.attachBinary(stream, opts, function(err) {
        if (err) {
          addUrlErr(url);
          log.error(which + " " + err);
        } else {
          log.debug(which + " ok");
        }
        return cb(err);
      });

      /* This is a huge hack to not setHeader if length
          is null, this is caused by streaming resize
          Check after cozydb update
       */
      return request.setHeader = function(header, length) {};
    };
    return async.series([
      function(cb) {
        return attach('raw', raw, cb);
      }, function(cb) {
        var thumbStream;
        thumbStream = thumb.pipe(resizeThumb);
        return attach('thumb', thumbStream, cb);
      }, function(cb) {
        var screenStream;
        screenStream = screen.pipe(resizeScreen);
        return attach('screen', screenStream, cb);
      }
    ], done);
  });
};

module.exports = function(access_token, done) {
  gdataClient.setToken({
    access_token: access_token
  });
  log.debug("get album list");
  return gdataClient.getFeed(ALBUMS_URL, function(err, feed) {
    var numberAlbumProcessed;
    log.debug("got list err=" + err);
    if (err) {
      return done(err);
    }
    numberAlbumProcessed = 0;
    numberPhotosProcessed = 0;
    total = 0;
    return getTotal(feed.feed.entry, function() {
      return async.eachSeries(feed.feed.entry, function(gAlbum, next) {
        return importAlbum(gAlbum, function(err) {
          if (err) {
            log.error(err);
          } else {
            log.debug("done with 1 album");
          }
          realtimer.sendPhotosAlbum({
            number: ++numberAlbumProcessed
          });
          return next(null);
        });
      }, function(err) {
        var _;
        if (err) {
          return done(err);
        }
        _ = localizationManager.t;
        notification.createOrUpdatePersistent("leave-google-photos", {
          app: 'import-from-google',
          text: _('notif_import_photo', {
            total: numberPhotosProcessed
          }),
          resource: {
            app: 'photos',
            url: 'photos/'
          }
        });
        return done();
      });
    });
  });
};
