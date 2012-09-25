express = require('express')
stylus = require('stylus')
app = express.createServer()
io = require('socket.io').listen(app)

app.configure ->
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use stylus.middleware({src: __dirname + '/src', dest: __dirname + '/public'})
  app.use express.static(__dirname + '/public')
  app.use app.router
app.configure 'development', -> app.use express.errorHandler({dumpExceptions: true, showStack: true})
app.configure 'production', -> app.use express.errorHandler()

users =
  'Fabien Pinckaers': {name: 'Fabien Pinckaers', username: 'fp', online: false, channels: []}
  'Antony Lesuisse': {name: 'Antony Lesuisse', username: 'al', online: false, channels: []}
  'Minh Tran': {name: 'Minh Tran', username: 'mit', online: false, channels: []}
  'Frederic van der Essen': {name: 'Frederic van der Essen', username: 'fva', online: false, channels: []}
  'Julien Thewys': {name: 'Julien Thewys', username: 'jth', online: false, channels: []}
  'Nicoleta Gherlea': {name: 'Nicoleta Gherlea', username: 'ngh', online: false, channels: []}

app.get '/users', (req, res) -> res.json(v for k, v of users)
app.get '/*', (req, res) -> res.render('index.jade', title: 'OpenERP')

io.sockets.on 'connection', (socket) ->
  socket.on 'connect', (name) ->
    socket.name = name
    users[name].online = true
    users[name].sid = socket.id
    socket.broadcast.emit('connect', name)
  socket.on 'disconnect', ->
    socket.broadcast.emit('disconnect', socket.name)
    users[socket.name].online = false
  #socket.on 'message', (data) -> socket.broadcast.emit('message', {name: socket.name, msg: data})
  socket.on 'pm', (data) ->
    d = JSON.parse(data)
    io.sockets.socket(users[d.to].sid).emit('pm', {from: d.from, to: d.to, msg: d.msg}) if users[d.to].sid?
    #return false

app.listen(3000)
console.log('http://localhost:3000/')
