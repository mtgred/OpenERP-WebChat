class User extends Backbone.Model

class UserView extends Backbone.View
  tagName: 'li'
  className: 'user'
  initialize: ->
    @model.bind 'remove', => $(@.el).remove()
  template: _.template $('#chat-user').html()
  render: -> $(@el).html(@template @model.toJSON())

class UsersView extends Backbone.View
  className: 'users'
  template: _.template $('#user-list').html()
  initialize: ->
    @collection.bind('add', @addUser)
    $('.chatapp').append($(@el).html(@template({})))
  addUser: (user) => $(@el).find('> ul').append (new UserView(model: user)).render()

class MessageView extends Backbone.View
  tagName: 'li'
  className: 'msg'
  template: _.template $('#chat-message').html()
  render: -> $(@el).html(@template @model.toJSON())

class ChatView extends Backbone.View
  className: 'chatview'
  template: _.template $('#chat').html()
  initialize: ->
    @collection.bind('add', @addMessage)
    $('.chat-window').append($(@el).html(@template(title: 'Foobar')))
  events:
    'submit form': 'sendMessage'
    'click .close': 'close'
  addMessage: (msg) =>
    $(@el).find('.messages > ul').append((new MessageView model: msg).render()).parent().scrollTop(99999)
  sendMessage: (e) =>
    input = $(@el).find('.prompt').val()
    if input
      chatapp.socket.send(JSON.stringify({username: localStorage['username'], msg: input}))
      @collection.add(username: localStorage['username'], msg: input)
    $(@el).find('.prompt').val('')
    return false
  close: => $(@el).hide()

class ChatMenuView extends Backbone.View
  tagName: 'li'
  template: _.template $('#chat-menu').html()
  initialize: ->
    @collection.bind('add', @render)
    @collection.bind('remove', @render)
    $('.nav.pull-right').prepend(@el)
    @render()
  events: 'click': 'toggle'
  render: => $(@el).html(@template(usercount: @collection.length))
  toggle: =>
    $(@el).toggleClass('active')
    offset = if $(@el).hasClass('active') then '0' else '-210'
    $('.chatapp').animate(right: offset)
    return false

class Chat
  constructor: (@title) ->
    @messages = new Backbone.Collection
    @users = new Backbone.Collection
    @usersView = new UsersView(collection: @users)
    @chatmenuView = new ChatMenuView(collection: @users)
    @chatView = new ChatView(collection: @messages)
  addMessage: (msg) => @messages.add(msg)
  addUser: (username) => @users.add(new User username: username)
  removeUser: (username) =>
    @users.each (user) -> user.destroy() if user.get('username') is username

class ChatApp
  constructor: ->
    @socket = io.connect('/')
    @socket.emit "join", localStorage["username"]
    @socket.on "join", (username) => @chats['general'].addUser(username)
    @socket.on "disconnect", (username) => @chats['general'].removeUser(username)
    @socket.on "close", -> alert('Connection lost')
    @socket.on "message", (data) => @chats['general'].addMessage(JSON.parse(data['msg']))
    @socket.on "userlist", (userlist) => @chats['general'].addUser(k) for k, v of userlist
  chats: { general: new Chat('general') }

$ ->
  localStorage['username'] = 'Guest ' + Math.floor(Math.random() * 1000) unless localStorage['username']
  $('.user-box').text(localStorage['username'])
  $('#change-name .save').click ->
    $('.user-box').text($('#change-name input').val())
    localStorage['username'] = $('#change-name input').val()

  window.chatapp = new ChatApp

#Backbone.sync = (method, model, options) ->
  #app.socket.send(model.attributes) if method is 'create'
