BaseView = require '../lib/base_view'

module.exports = class LeaveGoogleView extends BaseView

    template: require './templates/leave_google_form'
    tagName: 'main'
    id: 'leave-google'

    events:
        'click  a#connect-google': 'connectWithGoogle'
        'keypress #auth_code': 'onAuthCodeKeypress'
        'click #step-pastecode-ok': 'onStep2Done'
        'click #step-pastecode-ko': 'onStep2Cancel'
        'click #lg-login': 'submitLg'

    changeStep: (step) ->
        @$('.step').hide()
        @$("#step-#{step}").show()
        @$('#auth_code').focus() if step is 'pastecode'

    afterRender: ->
        @changeStep 'bigbutton'

    connectWithGoogle: (event)->
        event.preventDefault()
        opts = [
            'toolbars=0'
            'width=700'
            'height=600'
            'left=200'
            'top=200'
            'scrollbars=1'
            'resizable=1'
        ].join(',')
        @popup = window.open window.oauthUrl, 'Google OAuth',opts
        @changeStep 'pastecode'

    onStep2Done: (event)->
        event.preventDefault()
        @popup?.close()
        @changeStep 'pickscope'

    onStep2Cancel: (event)->
        event.preventDefault()
        @popup?.close()
        @changeStep 'bigbutton'

    onAuthCodeKeyup: (event) ->
        @onStep2Done(event) if event.keyCode is 13 #ENTER
        @onStep2Done(event) if event.keyCode is 27 #ESCAPE


    submitLg: (event)->
        event.preventDefault()
        auth_code = @$("input:text[name=auth_code]").val()
        @$("input:text[name=auth_code]").val("")

        scope =
            photos: @$("input:checkbox[name=photos]").prop("checked")
            calendars: @$("input:checkbox[name=calendars]").prop("checked")
            contacts: @$("input:checkbox[name=contacts]").prop("checked")

        $.post "lg", {auth_code: auth_code, scope: scope}
        window.app.router.navigate 'status', true
