{exec} = require 'child_process'
fs     = require 'fs'
logger = require('printit')
            date: false
            prefix: 'cake'

option '-f', '--file [FILE*]' , 'List of test files to run'
option '-d', '--dir [DIR*]' , 'Directory of test files to run'
option '-e' , '--env [ENV]', 'Run tests with NODE_ENV=ENV. Default is test'
option '' , '--use-js', 'If enabled, tests will run with the built files'

options =  # defaults, will be overwritten by command line options
    file        : no
    dir         : no

buildJsInLocales = ->
    path = require 'path'
    # server files
    for file in fs.readdirSync './server/locales/'
        filename = './server/locales/' + file
        template = fs.readFileSync filename, 'utf8'
        exported = "module.exports = #{template};\n"
        name     = file.replace '.json', '.js'
        fs.writeFileSync "./build/server/locales/#{name}", exported
    exec "rm -rf build/server/locales/*.json"


task 'build', 'Build Json to Javascript (transifex)', ->
    logger.options.prefix = 'cake:build'
    logger.info "Start compilation..."
    command = """
        mkdir -p build/server/locales/ &&
        rm -rf build/server/locales/*
    """
    exec command, (err, stdout, stderr) ->
        if err
            logger.error "An error has occurred while compiling:\n" + err
            process.exit 1
        else
            buildJsInLocales()
            logger.info "Compilation succeeded."
            process.exit 0
