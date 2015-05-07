americano = require 'americano'

americano.start
    root: __dirname
    name: 'template'
    port: process.env.PORT || 9250
    host: process.env.HOST || '127.0.0.1'