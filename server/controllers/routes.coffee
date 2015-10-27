index = require './leavegoogle'

module.exports =
    '':
        get: index.index
    'lg':
        post: index.lg
    # log client errors
    'log':
        post: index.logClient
