require('./extra-modules-path')

const fs = require('fs')
const track = require('.')
const argv = require('minimist')(process.argv.slice(2))

if (!argv.socketPath) {
  console.error(`USAGE: ${process.argv[1]} --socketPath SOCKET [--debounce MILLISECONDS]`)
  process.exit(1)
}

track(argv.socketPath, onChange, {
  debounce: argv.debounce
})

function onChange(kvm) {
  console.log('XXXXX', kvm)
}
