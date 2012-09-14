{spawn, exec} = require 'child_process'

task 'watch', 'Watch source files and build JS & CSS', (options) ->
  runCommand = (name, args...) ->
    proc =           spawn name, args
    proc.stderr.on   'data', (buffer) -> console.log buffer.toString()
    proc.stdout.on   'data', (buffer) -> console.log buffer.toString()
    proc.on          'exit', (status) -> process.exit(1) if status isnt 0
  #runCommand 'coffee', '-r', 'coffeescript-growl', '-o', 'static/js', '-wc', 'src'
  runCommand 'coffee', '-o', 'public/js', '-wc', 'src'
  #runCommand 'sass', '--watch', 'client:client'
  #runCommand 'coffee', '-wc', 'test'

