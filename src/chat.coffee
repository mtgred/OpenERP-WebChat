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
      @addUser(u) for u in @collection.filter (u) -> ~u.get('name').toLowerCase().indexOf(s)
      $('.searchclear').fadeIn('fast')
    else
      @searchclear()
  searchclear: =>
    $('.searchclear').fadeOut('fast')
    $('.searchbox').val('').focus()
    @render()

class Messages extends Backbone.Collection
  add: (msg) ->
    m = @last()
    if m? and m.get('from') is msg.from
      m.get('messages').push(msg)
      m.trigger("change")
    else
      super(from: msg.from, to: msg.to, messages: [msg])

class MessageView extends Backbone.View
  tagName: 'li'
  className: 'msg'
  template: _.template $('#chat-message').html()
  initialize: -> @model.bind('change', @render)
  render: => $(@el).html(@template @model.toJSON())

class ChatView extends Backbone.View
  tagName: 'li'
  className: 'chat-window'
  template: _.template $('#chat').html()
  initialize: ->
    @collection.bind('add', @addMessage)
    @collection.bind('all', @show)
    $('.chat-windows').append($(@el).html(@template(title: @options.dest)))
    $('.prompt').focus()
  events:
    'submit form': 'sendMessage'
    'click header': 'toggle'
    'click .close': -> $(@el).hide(); @toggle()
  unreadMsg: 0
  addMessage: (msg) => $(@el).find('.messages').append((new MessageView model: msg).render())
  sendMessage: (e) =>
    e.preventDefault()
    input = $(@el).find('.prompt').val()
    if input
      m = {from: localStorage['name'], to: @options.dest, msg: input, time: new Date()}
      app.socket.emit 'pm', JSON.stringify(m)
      @collection.add(m)
    $(@el).find('.prompt').val('')
  show: =>
    $(@el).show().find('.messages').scrollTop(99999); $('.prompt').focus()
    $(@el).find('.unreadMsg').text(++@unreadMsg).show() if $(@el).hasClass('folded')
  toggle: =>
    if $(@el).hasClass('folded')
      $(@el).animate { height: '380px' }, complete: =>
        $(@el).removeClass('folded').find('.unreadMsg').hide()
        $('.prompt').focus()
      @unreadMsg = 0
    else
      $(@el).animate({ height: '25px' }, { complete: => $(@el).addClass('folded') })

class ChatMenuView extends Backbone.View
  tagName: 'li'
  className: 'active'
  template: _.template $('#chat-menu').html()
  initialize: ->
    @collection.bind('all', @render)
    $('.nav.pull-right').prepend(@el)
    @render()
  events: 'click': 'toggle'
  render: =>
    $(@el).html(@template(usercount: (@collection.filter (u) -> u.get('online')).length))
  toggle: =>
    $(@el).toggleClass('active')
    offset = if $(@el).hasClass('active') then 0 else -220
    $('.chatapp').animate(right: offset)
    $('.chat-windows').animate(right: offset + 220)
    return false

class Channel
  constructor: (@dest) ->
    @messages = new Messages
    @chatView = new ChatView(collection: @messages, dest: @dest)
  addMessage: (msg) ->
    msg.time = new Date(msg.time)
    @messages.add(msg)

class ChatApp
  constructor: ->
    @users = new Backbone.Collection()
    @usersView = new UsersView(collection: @users)
    @socket = io.connect('/')
    @socket.on "error", (err) -> console.log err
    @socket.on "connected", (data) =>
      @user = data.user
      localStorage['uid'] = @user.id
      $('.user-box').text(@user.name)
      $('.user-box').prepend("<img src='/img/avatar/#{@user.id}.jpeg' class='avatar' />")
      $('.login').fadeOut()
      $('.container').fadeIn()
      @users.reset(u for u in data.users when u.id isnt @user.uid)
    if localStorage['uid']?
      $('.login').hide()
      $('.container').show()
      @socket.emit "logged", uid: localStorage['uid']
    @socket.on "connect", (id) => @users.each (u) -> u.set('online', true) if u.get('id') is id
    @socket.on "disconnect", (id) => @users.each (u) -> u.set('online', false) if u.get('id') is id
    @socket.on "pm", (data) =>
      @createChannel(data.from) unless @channels[data.from]?
      @channels[data.from].addMessage(data)
  channels: {}
  createChannel: (dest) =>
    if @channels[dest]?
      @channels[dest].chatView.show()
    else
      @channels[dest] = new Channel(dest)
  login: (login, password) -> @socket.emit "login", { login: login, pwd: password }

$ ->
  window.app = new ChatApp
  $('.login').submit (e) ->
    e.preventDefault()
    app.login $("input[name='login']").val(), $("input[name='password']").val()


  $('#change-name .save').click ->
    $('.user-box').text($('#change-name input').val())
    localStorage['name'] = $('#change-name input').val()
