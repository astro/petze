BY_TYPE = {}

class BY_TYPE.change_timeout
    constructor: (@name, {@timeout}) ->
        @last_change = new Date().getTime() / 1000
        @last_value = null

    run: (report, value) ->
        now = new Date().getTime() / 1000
        if value isnt @last_value
            @last_change = now
            @last_value = value
        else if (overdue = now - @last_change - @timeout) >= 0
            report("#{@name} is overdue by #{overdue}s at #{@last_value}")

class BY_TYPE.match
    constructor: (@name, {@matcher}) ->

    run: (report, value) ->
        unless @matcher(value)
            report("#{@name} doesn't match")

exports.create = (name, config) ->
    new BY_TYPE[config.type](name, config)