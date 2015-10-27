ErrorHandler = require './lib/error_helper'
Router = require './router'

window.onError = ErrorHandler.onerror

# The function called from index.html
# Starts the application
$ ->

    try
        window.app = {}
        # Localization management
        locale = window.locale
        polyglot = new Polyglot()
        try
            locales = require "locales/#{locale}"
        catch e
            locale = 'en'
            locales = require 'locales/en'

        polyglot.extend locales
        window.t = polyglot.t.bind polyglot

        # Initialize routing
        window.app.router = new Router()
        Backbone.history.start()


        url = window.location.origin
        pathToSocketIO = "/#{window.location.pathname.substring(1)}socket.io"
        console.log toto.titi

        window.sio = io url,
            path: pathToSocketIO
            reconnectionDelayMax: 60000
            reconectionDelay: 2000
            reconnectionAttempts: 3

    catch e
        ErrorHandler.catchError e
