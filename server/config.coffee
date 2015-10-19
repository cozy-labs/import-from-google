americano = require 'americano'
fs        = require 'fs'
path      = require 'path'
realtimer = require './utils/realtimer'

localizationManager = require './utils/localization_manager'

useBuildView = fs.existsSync path.resolve(__dirname, 'views', 'index.js')

config =
    common:
        set:
            'view engine': if useBuildView then 'js' else 'jade'
            'views': path.resolve __dirname, 'views'
        engine:
            js: (path, locales, callback) ->
                callback null, require(path)(locales)
        use:[
            americano.bodyParser()
            americano.methodOverride()
            americano.errorHandler
                dumpExceptions: true
                showStack: true
            americano.static path.resolve(__dirname, '../client/public'),
                maxAge: 86400000
        ]
        afterStart: (app, server) ->
            sio = require 'socket.io'
            app.io = sio server

            app.io.on 'connection', (socket) ->
                realtimer.set(socket)

            localizationManager.initialize ->
                console.log "LocalizationManager initialized"


    development: [
        americano.logger 'dev'
    ]

    production: [
        americano.logger 'short'
    ]

    plugins: [
        'cozydb'
    ]

module.exports = config
