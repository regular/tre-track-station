const fs = require('fs')
const {join, resolve} = require('path')
const ssbClient = require('scuttlebot-release/node_modules/ssb-client')
const ssbKeys = require('scuttlebot-release/node_modules/ssb-keys')
const TrackStation = require('.')
const watch = require('mutant/watch')
const debounce = require('debounce')
const argv = require('minimist')(process.argv.slice(2))

const {restart} = argv

if (argv._.length<1) {
  console.error(`USAGE: ${process.argv[1]} --restart RESTARTCOMMAND SSBCONFIGFILE`)
  process.exit(1)
}

const config = JSON.parse(fs.readFileSync(argv._[0]))
const path = config.path || resolve(argv._[0], '../.tre')
if (!path) {
  console.error('config.path not set in', config.config)
  process.exit(1)
}

const keys = ssbKeys.loadSync(join(path, 'secret'))
if (!keys) {
  console.error('secret not found in', path)
  process.exit(1)
}

module.exports = function(_onChange) {
  track(config, keys)

  const onChange = debounce(_onChange, 2000)

  function track(conf, keys) {
    ssbClient(keys, Object.assign({},
      conf,
      {
        manifest: {
          whoami: 'async',
          revisions: {
            messagesByType: 'source',
            heads: 'source'
          }
        }
      }
    ), (err, ssb) => {
      if (err) {
        console.error(err.message)
        process.exit(1)
      }
      const trackStation = TrackStation(ssb)
      const station = trackStation()
      watch(station, kv => {
        onChange(kv)
      })
    })
  }
}
