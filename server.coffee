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
app.get '/*', (req, res) -> res.render 'index.jade', title: 'OpenERP'

# Socket.io
connected = {}
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
