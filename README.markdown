# petze

petze is simple service monitoring not invented here. It polls a set
of service by a specified interval and reports failure by
email. Configuration is done programmatically.

# Configuration

`config.coffee` exports petze's configuration. As the file is normal
CoffeeScript, you are free to abstract repetitive things away.

## exports.interval

Polling interval in seconds.

## exports.notify

A list of e-mail addresses to send reports to.

## exports.min_notification_interval

Mail bomb prevention measure: 1800 (half hours) amounts to 48 mails
per day max.

## exports.sources

Dictionary of data sources, identifiers pointing to another specific
dictionary.

The `type` field designates the kind of source:

* `http` sources fetch a `url`. Optional paramaters are: `timeout` (in
  seconds), `host`, `port`
* `exec` runs a `cmd` and yields *stdout* on exit code `0`
* `json` sources another `source` and parses its data into an object

## exports.watches

A watch checks for validity. Any **source** you want to check must be
consumed by a watch! They are structured similarly to `sources`. Valid
`type`s are:

* `match` specifies a `matcher` callback that receives data from its
  `source` and must return `true` on success or `false` on failure.
* `change_timeout` monitors a value and fails when it has seen no
  update in the specified `interval` (in seconds). This can be used to
  detect silent lock-ups in services that should be busy
  around-the-clock.

# Running it

`./run.sh`

We recommend running petze under supervision (eg. **runit**).


# Improve it!

* Don't be lazy, write a `package.json`, along with a `Cakefile` and
  release with compiled `.js` files!
* Make error reporting a tad more verbose.
* Make reports clearable by source/watch so recipients don't see old
  errors.
