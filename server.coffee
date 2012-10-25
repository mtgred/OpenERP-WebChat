stylus = require('stylus')
express = require('express')
app = express()
server = require('http').createServer(app)
io = require('socket.io').listen(server)
xmlrpc = require('xmlrpc')
fs = require('fs')
mongoose = require('mongoose')
Schema = mongoose.Schema

# Mongoose
db = mongoose.createConnection('localhost', 'webchat')
messageSchema = new Schema
  from: String
  to: String
  msg: [String]
  time: { type: Date, default: Date.now }
Message = db.model('Message', messageSchema)

# Express
app.configure ->
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use stylus.middleware({src: __dirname + '/src', dest: __dirname + '/public'})
  app.use express.static(__dirname + '/public')
  app.use app.router
app.configure 'development', -> app.use express.errorHandler({dumpExceptions: true, showStack: true})
app.configure 'production', -> app.use express.errorHandler()

db = 'foobar'
uid = 1
pwd = 'admin'
host = 'localhost'
domain = []

db = 'openerp'
uid = 138
pwd = 'h4WeH55k'
host = 'openerp.my.openerp.com'
domain = [['company_id','=',1]]

port = 8069
lc = xmlrpc.createClient({ host: host, port: port, path: '/xmlrpc/common' })
fc = xmlrpc.createClient({ host: host, port: port, path: '/xmlrpc/object' })
users = {}
fc.methodCall 'execute', [db,uid,pwd,'hr.employee','search',domain], (err, uids) ->
  fc.methodCall 'execute', [db,uid,pwd,'hr.employee','read',uids, ['name','user_id','photo']], (err, empls) ->
    for e in empls
      if e.user_id
        users[e.user_id[0]] = { name: e.name, id: e.user_id[0].toString(), image: 'avatar', online: false, messages: [], sids: [] }
        if e.photo
          users[e.user_id[0]].image = e.user_id[0]
          fs.writeFile("public/img/avatar/#{e.user_id[0]}.jpeg", new Buffer(e.photo, "base64"), "binary", (err) -> console.log err if err)
    console.log 'Ready'

app.get '/*', (req, res) -> res.render('index.jade', title: 'OpenERP')

io.sockets.on 'connection', (socket) ->
  logged = (uid) ->
    socket.uid = uid
    users[uid].online = true
    users[uid].sids.push(socket.id)
    socket.broadcast.emit('connect', uid)
    data = {user: users[uid], users: {id: v.id, name: v.name, image: v.image, online: v.online} for k, v of users}
    socket.emit('connected', data)
    socket.emit('pm', msg) for msg in users[uid].messages
    users[uid].messages = []

  socket.on 'disconnect', ->
    if socket.uid?
      users[socket.uid].sids.splice(users[socket.uid].sids.indexOf(socket.id), 1)
      if users[socket.uid].sids.length is 0
        users[socket.uid].online = false
        io.sockets.emit('disconnect', socket.uid)
  socket.on 'logged', (data) -> logged(data.uid)
  socket.on 'login', (data) ->
    lc.methodCall 'login', [db, data.login, data.pwd], (err, uid) ->
      if uid then logged(uid.toString()) else socket.emit 'error', 'Wrong login or password'
  socket.on 'pm', (data) ->
    d = JSON.parse(data)
    d.time = new Date()
    (new Message(d)).save (err) -> console.error(err) if err
    if users[d.to].online
      io.sockets.socket(sid).emit('pm', d) for sid in users[d.to].sids
    else
      users[d.to].messages.push(d)
    io.sockets.socket(sid).emit('pm', d) for sid in users[d.from].sids
  socket.on 'getMessageLog', (data) ->
    uid = JSON.parse(data).uid
    Message.find().or([{from: socket.uid, to: uid}, {from: uid, to: socket.uid}]).limit(50).exec (err, msgs) ->
      console.error(err) if err
      socket.emit('messageLog', {uid: uid, msgs: msgs})


server.listen(3000)
console.log('http://localhost:3000')
