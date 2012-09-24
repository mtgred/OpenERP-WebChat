express = require('express')
stylus = require('stylus')
app = express.createServer()
io = require('socket.io').listen(app)

# Express config
app.configure ->
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use express.cookieParser()
  app.use express.session(secret: 'your secret here')
  app.use stylus.middleware({src: __dirname + '/src', dest: __dirname + '/public'})
  app.use express.static(__dirname + '/public')
  app.use app.router

app.configure 'development', ->
  app.use express.errorHandler({dumpExceptions: true, showStack: true})

app.configure 'production', ->
  app.use express.errorHandler()

# Routes
userdata: [
  {name: 'Fabien Pinckaers', username: 'fp'},
  {name: 'Antony Lesuisse', username: 'al'},
  {name: 'Minh Tran', username: 'mit'},
  {name: 'Frederic van der Essen', username: 'fva'}
  {name: 'Julien Thewys', username: 'jth'}
  {name: 'Nicoleta Gherlea', username: 'ngh'}
]
app.get '/users', (req, res) -> res.json(userdata)
app.get '/*', (req, res) -> res.render('index.jade', title: 'OpenERP')

# Socket.io
connected = {}
channels = []
users = { name: u.name, username: u.username, online: false, channels: [] } for u in userdata

#users
io.sockets.on 'connection', (socket) ->
  socket.on 'join', (username) ->
    socket.broadcast.emit 'join', username
    socket.emit('userlist', connected)
    socket.username = username
    connected[username] = ''

  socket.on 'disconnect', ->
    socket.broadcast.emit 'disconnect', socket.username
    delete connected[socket.username]

  socket.on 'message', (data) ->
    socket.broadcast.emit 'message', {username: socket.username, msg: data}

# Main
app.listen(3000)
console.log('http://localhost:3000/')
