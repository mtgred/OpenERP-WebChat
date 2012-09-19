class User extends Backbone.Model

class UserView extends Backbone.View
  tagName: 'li'
  className: 'user'
  template: _.template $('#chat-user').html()
  initialize: -> @model.bind 'remove', => $(@el).remove()
  events: 'click': 'createChannel'
  render: -> $(@el).html(@template @model.toJSON())
  createChannel: -> console.log @model.get('name')

class UsersView extends Backbone.View
  className: 'users'
  template: _.template $('#user-list').html()
  initialize: ->
    @collection.bind('add', @addUser)
    @collection.bind('reset', @render)
    $('.chatapp').append($(@el).html(@template({})))
    @collection.each (user) => @addUser(user)
  events:
    'keyup .searchbox': 'filter'
    'click .searchclear': 'searchclear'
  addUser: (user) => $(@el).find('> ul').append (new UserView(model: user)).render()
  render: =>
    $(@el).find('> ul').empty()
    @collection.each (user) => @addUser(user)
  filter: =>
    s = $('.searchbox').val().toLowerCase()
    if s
      $(@el).find('> ul').empty()
      @addUser(u) for u in @collection.filter (u) -> ~u.get('name').toLowerCase().indexOf s
      $('.searchclear').fadeIn('fast')
    else
      @searchclear()
  searchclear: =>
    $('.searchclear').fadeOut('fast')
    $('.searchbox').val('').focus
    @render()

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
    $('.chat-window').append($(@el).html(@template(title: 'General')))
  events:
    'submit form': 'sendMessage'
    'click .close': 'close'
  addMessage: (msg) =>
    $(@el).find('.messages > ul').append((new MessageView model: msg).render()).parent().scrollTop(99999)
  sendMessage: (e) =>
    input = $(@el).find('.prompt').val()
    if input
      app.socket.send(JSON.stringify({username: localStorage['username'], msg: input}))
      @collection.add(username: localStorage['username'], msg: input)
    $(@el).find('.prompt').val('')
    return false
  close: => $(@el).hide()

class ChatMenuView extends Backbone.View
  tagName: 'li'
  className: 'active'
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
    offset = if $(@el).hasClass('active') then '0' else '-220'
    $('.chatapp').animate(right: offset)
    return false

class Channel
  constructor: (@title) ->
    @messages = new Backbone.Collection
    @users = new Backbone.Collection
    @chatView = new ChatView(collection: @messages)
  addMessage: (msg) => @messages.add(msg)
  addUser: (username) => @users.add(new User username: username)
  removeUser: (username) => @users.each (user) -> user.destroy() if user.get('username') is username

class ChatApp
  constructor: ->
    @socket = io.connect('/')
    @socket.emit "join", localStorage["username"]
    @socket.on "join", (username) => @channels['general'].addUser(username)
    @socket.on "disconnect", (username) => @channels['general'].removeUser(username)
    @socket.on "close", -> alert('Connection lost')
    @socket.on "message", (data) => @channels['general'].addMessage(JSON.parse(data['msg']))
    @socket.on "userlist", (userlist) => @channels['general'].addUser(k) for k, v of userlist
    @users = new Backbone.Collection(@userdata)
    @usersView = new UsersView(collection: @users)
    @chatmenuView = new ChatMenuView(collection: @users)
  channels: { general: new Channel('general') }
  userdata: [
    {name: 'Fabien Pinckaers', username: 'fp'},
    {name: 'Antony Lesuisse', username: 'al'},
    {name: 'Minh Tran', username: 'mit'},
    {name: 'Frederic van der Essen', username: 'fva'}
    {name: 'Julien Thewys', username: 'jth'}
    {name: 'Nicoleta Gherlea', username: 'ngh'}
  ]

$ ->
  localStorage['username'] = 'Guest ' + Math.floor(Math.random() * 1000) unless localStorage['username']
  $('.user-box').text(localStorage['username'])
  $('#change-name .save').click ->
    $('.user-box').text($('#change-name input').val())
    localStorage['username'] = $('#change-name input').val()

  window.app = new ChatApp

#Backbone.sync = (method, model, options) ->
  #app.socket.send(model.attributes) if method is 'create'
