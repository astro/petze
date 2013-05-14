child_process = require 'child_process'

{ SourcesResolver } = require './sources'
watches = require './watches'
config = require './config'

sendMail = (subject, mailTo, body) ->
    mail = child_process.spawn("mail", ["-s", subject, mailTo])
    mail.stdin.write(body)
    mail.stdin.end()
    mail.on 'exit', (code) ->
        if code isnt 0
            report("mail exited with #{code}")
            can_flush_reports()

current_report = []
report = (msg) ->
    msg = "#{msg}"
    console.error(msg)
    current_report.push(msg)

can_flush_reports = () ->
    console.log "sendMail", current_report.length
    # TODO: sendMail
    current_report = []


named_watches = {}
for own watch_name, watch_config of config.watches
    named_watches[watch_name] = watches.create watch_name, watch_config

poll = ->
    src_res = new SourcesResolver()
    pending = 0
    for own watch_name, watch_config of config.watches
        do (watch_name, watch_config) ->
            done = (err, value) ->
                pending--
                if err
                    report(err.stack || err)
                else
                    try
                        if watch_config.key
                            key_parts = watch_config.key.split(".")
                            while key_parts.length > 0
                                value = value[key_parts.shift()]
                        named_watches[watch_name].run(report, value)
                    catch e
                        report(e.stack)
                if pending < 1
                    console.log "Poll done"
                    can_flush_reports()

            if watch_config.source
                src_res.consume(watch_config.source, done)
            else
                process.nextTick(done)
            pending++
    console.log "Polling, #{pending} pending"

setInterval poll, config.interval * 1000
poll()

