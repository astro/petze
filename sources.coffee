{ get } = require 'http'
{ parse: urlParse } = require 'url'
child_process = require 'child_process'

config = require './config'

MAX_SIZE = 1024 * 1024  # 1 MB
BY_TYPE = {}

class BY_TYPE.http
    constructor: ({@url, @timeout, @host, @port}) ->

    run: (cb) ->
        opts = urlParse(@url)
        if @host
            opts.hostname = @host
        addr = "#{opts.hostname}"
        if @port
            opts.port = @port
            addr += " port #{opts.port}"
        get opts, (res) =>
            console.log("got #{@url}", res.statusCode)
            @data = ""
            res.setEncoding 'utf8'
            res.on 'data', (data) =>
                if @data.length < MAX_SIZE
                    @data += data
            res.on 'end', =>
                cb?(null, @data)
                cb = null
            res.on 'error', (err) ->
                cb?(err)
                cb = null
        .on 'error', (err) ->
            cb?(err)
            cb = null
        timeout = setTimeout ->
            cb?(new Error("HTTP timeout for #{addr}"))
            cb = null
        , (if @timeout then @timeout * 1000 else 30000)
        old_cb = cb
        cb = (err, value) ->
            clearTimeout(timeout)
            old_cb(err, value)


class BY_TYPE.json
    constructor: ({@data}) ->

    run: (cb) ->
        val = null
        err = null
        try
            val = JSON.parse(@data)
        catch e
            err = e
        cb?(val, err)

class BY_TYPE.exec
    constructor: ({ @cmd }) ->

    run: (cb) ->
        child_process.exec @cmd, (error, stdout, stderr) ->
            if error
                cb error
            else
                cb null, stdout


class SourceRunner
    constructor: (name, source_config) ->
        @cbs = []
        unless BY_TYPE[source_config.type]
            return cb(new Error("No such source type #{source_config.type}"))
        @source = new BY_TYPE[source_config.type](source_config)
        @source.run (@err, @value) =>
            for cb in @cbs
                cb(@err, @value)
            delete @cbs

    consume: (cb) ->
        if @cbs
            @cbs.push(cb)
        else
            cb(@error, @value)

class exports.SourcesResolver
    constructor: ->
        @runners = {}

    consume: (name, cb) ->
        run = (value) =>
            config.sources[name].value = value
            unless @runners.hasOwnProperty name
                @runners[name] = new SourceRunner(name, config.sources[name])
            # @runners[name].consume(cb)
            @runners[name].consume (err, val) ->
                cb(err, val)

        if config.sources[name].source
            # defer
            @consume config.sources[name].source, (err, value) ->
                if err
                    cb(err)
                else
                    run(value)
        else
            # run
            run(null)

