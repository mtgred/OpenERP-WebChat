class User extends Backbone.Model

class UserView extends Backbone.View
  tagName: 'li'
  className: 'user'
  template: _.template $('#chat-user').html()
  initialize: ->
    @model.bind 'remove', => $(@el).remove()
    @model.bind 'change', => @render()
  events: 'click': -> window.app.createChannel(@model.get('name'))
  render: -> $(@el).html(@template @model.toJSON())

class UsersView extends Backbone.View
  className: 'users'
  template: _.template $('#user-list').html()
  initialize: ->
    @collection.bind('add', @addUser)
    @collection.bind('reset', @render)
    $('.chatapp').append($(@el).html(@template({})))
    @render()
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
    $('.searchbox').val('').focus()
    @render()

class MessageView extends Backbone.View
  tagName: 'li'
  className: 'msg'
  template: _.template $('#chat-message').html()
  render: -> $(@el).html(@template @model.toJSON())

class ChatView extends Backbone.View
  tagName: 'li'
  className: 'chat-window'
  template: _.template $('#chat').html()
  initialize:  ->
    @collection.bind('add', @addMessage)
    $('.chat-windows').append($(@el).html(@template(title: @options.dest)))
    $('.prompt').focus()
  events:
    'submit form': 'sendMessage'
    'click .close': -> $(@el).hide()
  addMessage: (msg) =>
    $(@el).find('.messages > ul').append((new MessageView model: msg).render()).parent().scrollTop(99999)
    @show()
  sendMessage: (e) =>
    input = $(@el).find('.prompt').val()
    if input
      app.socket.emit('pm', JSON.stringify({from: localStorage['name'], to: @options.dest, msg: input}))
      @collection.add(from: localStorage['name'], msg: input)
    $(@el).find('.prompt').val('')
    return false
  show: => $(@el).show()

class ChatMenuView extends Backbone.View
  tagName: 'li'
  className: 'active'
  template: _.template $('#chat-menu').html()
  initialize: ->
    @collection.bind('all', @render)
    $('.nav.pull-right').prepend(@el)
    @render()
  events: 'click': 'toggle'
  render: => $(@el).html @template(usercount: (@collection.filter (u) -> u.get('online')).length)
  toggle: =>
    $(@el).toggleClass('active')
    offset = if $(@el).hasClass('active') then 0 else -210
    $('.chatapp').animate(right: offset)
    $('.chat-windows').animate(right: offset + 210)
    return false

class Channel
  constructor: (@dest) ->
    #@users = new Backbone.Collection([localStorage['name'], user])
    @messages = new Backbone.Collection
    @chatView = new ChatView(collection: @messages, dest: @dest)
  addMessage: (msg) => @messages.add(msg)
  addUser: (username) => @users.add(new User username: username)
  removeUser: (username) => @users.each (user) -> user.destroy() if user.get('username') is username

class ChatApp
  constructor: ->
    @users = new Backbone.Collection(v for k, v of users when k isnt localStorage['name'])
    @usersView = new UsersView(collection: @users)
    @chatmenuView = new ChatMenuView(collection: @users)

    @socket = io.connect('/')
    @socket.emit "connect", localStorage['name']
    @socket.on "connect", (name) => @users.each (u) -> u.set('online', true) if u.get('name') is name
    @socket.on "disconnect", (name) => @users.each (u) -> u.set('online', false) if u.get('name') is name
    @socket.on "pm", (data) =>
      @createChannel(data.from) unless @channels[data.from]?
      @channels[data.from].addMessage(data)
  channels: {}
  createChannel: (dest) =>
    if @channels[dest]? then @channels[dest].chatView.show() else @channels[dest] = new Channel(dest)

$ ->
  window.app = new ChatApp
  localStorage['name'] = 'Guest ' + Math.floor(Math.random() * 1000) unless localStorage['name']
  $('.user-box').text(localStorage['name'])
  $('.user-box').prepend("<img src='/img/avatar/#{users[localStorage['name']].username}.jpeg' class='avatar' />")
  $('#change-name .save').click ->
    $('.user-box').text($('#change-name input').val())
    localStorage['name'] = $('#change-name input').val()
