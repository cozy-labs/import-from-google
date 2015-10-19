americano = require 'americano'


americano.start
    root: __dirname
    name: 'import-from-google'
    port: process.env.PORT or 9289
    host: process.env.HOST or '127.0.0.1'
