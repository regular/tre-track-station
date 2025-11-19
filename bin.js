require('./extra-modules-path')

const fs = require('fs')
const track = require('.')
const equal = require('deep-equal')
const argv = require('minimist')(process.argv.slice(2))

const outPath = "/etc/tre-station/content.json"

if (!argv.socketPath) {
  console.error(`USAGE: ${process.argv[1]} --socketPath SOCKET [--debounce MILLISECONDS]`)
  process.exit(1)
}

track(argv.socketPath, onChange, {
  debounce: argv.debounce
})

function onChange(kvm) {
  const {content} = kvm.value
  writeIfNew(content)
}

function writeIfNew(content) {
  let old
  try {
    old = JSON.parse(fs.readFileSync(outPath))
  } catch(err) {
    console.error(`Unable to read old config file: ${err.message}`)
  }
  if (equal(old, content)) {
    console.log('content did not change')
  } else {
    console.log('New content:')
    const json = JSON.stringify(content, null, 2)
    console.log(json)
    fs.writeFileSync(outPath, json, 'utf-8') 
  }
}
