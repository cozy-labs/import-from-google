FormView = require 'views/leave_google_form'
LogView = require 'views/leave_google_log'


mainView = null

module.exports = class Router extends Backbone.Router

    routes:
        '': 'main'
        'status': 'status'

    main: ->
        mainView?.remove()
        mainView = new FormView()
        mainView.render()
        $('body').empty().append mainView.$el

    status: ->
        mainView?.remove()
        mainView = new LogView()
        mainView.render()
        $('body').empty().append mainView.$el



