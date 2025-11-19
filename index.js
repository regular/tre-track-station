const ssbClient = require('./lib/tre-client')
const TrackStation = require('./track-station')
const watch = require('mutant/watch')
const debounce = require('debounce')

module.exports = function(socketPath, _onChange, opts) {
  opts = opts || {}
  track(socketPath)

  const onChange = debounce(_onChange, opts.debounce || 2000)

  function track(socketPath) {
    ssbClient(socketPath, (err, ssb) => {
      if (err) {
        console.error(err.message)
        return
      }
      const trackStation = TrackStation(ssb)
      const station = trackStation()
      watch(station, kv => {
        onChange(kv)
      })
    })
  }
}
