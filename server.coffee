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
  'Fabien Pinckaers': {name: 'Fabien Pinckaers', username: 'fp', online: false, messages: []}
  'Antony Lesuisse': {name: 'Antony Lesuisse', username: 'al', online: false, messages: []}
  'Minh Tran': {name: 'Minh Tran', username: 'mit', online: false, messages: []}
  'Frederic van der Essen': {name: 'Frederic van der Essen', username: 'fva', online: false, messages: []}
  'Julien Thewys': {name: 'Julien Thewys', username: 'jth', online: false, messages: []}
  'Nicoleta Gherlea': {name: 'Nicoleta Gherlea', username: 'ngh', online: false, messages: []}

app.get '/*', (req, res) -> res.render('index.jade', title: 'OpenERP', users: (v for k, v of users))

io.sockets.on 'connection', (socket) ->
  socket.on 'connect', (name) ->
    socket.name = name
    users[name].online = true
    users[name].sid = socket.id
    socket.broadcast.emit('connect', name)
    io.sockets.socket(socket.id).emit('pm', msg) for msg in users[name].messages
    users[name].messages = []
  socket.on 'disconnect', ->
    users[socket.name].online = false
    socket.broadcast.emit('disconnect', socket.name)
  socket.on 'pm', (data) ->
    d = JSON.parse(data)
    if users[d.to].online
      io.sockets.socket(users[d.to].sid).emit('pm', d)
    else
      users[d.to].messages.push(d)

app.listen(3000)
console.log('http://localhost:3000/')
