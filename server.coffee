express = require('express')
stylus = require('stylus')
app = express.createServer()
io = require('socket.io').listen(app)

app.configure ->
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use express.cookieParser()
  app.use express.session(secret: 'your secret here')
  app.use stylus.middleware({src: __dirname + '/src', dest: __dirname + '/public'})
  app.use express.static(__dirname + '/public')
  app.use app.router
app.configure 'development', -> app.use express.errorHandler({dumpExceptions: true, showStack: true})
app.configure 'production', -> app.use express.errorHandler()

users = [
  {name: 'Fabien Pinckaers', username: 'fp', online: false, channels: []}
  {name: 'Antony Lesuisse', username: 'al', online: false, channels: []}
  {name: 'Minh Tran', username: 'mit', online: false, channels: []}
  {name: 'Frederic van der Essen', username: 'fva', online: false, channels: []}
  {name: 'Julien Thewys', username: 'jth', online: false, channels: []}
  {name: 'Nicoleta Gherlea', username: 'ngh', online: false, channels: []}
]

app.get '/users', (req, res) -> res.json(users)
app.get '/*', (req, res) -> res.render('index.jade', title: 'OpenERP')

io.sockets.on 'connection', (socket) ->
  socket.on 'connect', (name) ->
    socket.name = name
    socket.broadcast.emit('connect', name)
    u.online = true for u in users when u.name is name
  socket.on 'disconnect', ->
    socket.broadcast.emit('disconnect', socket.name)
    u.online = false for u in users when u.name is socket.name
  socket.on 'message', (data) -> socket.broadcast.emit('message', {name: socket.name, msg: data})

app.listen(3000)
console.log('http://localhost:3000/')
