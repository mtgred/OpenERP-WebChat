class UserView extends Backbone.View
  tagName: 'li'
  className: 'clearfix'
  template: _.template $('#chat-user').html()
  initialize: ->
    @model.bind 'remove', => $(@el).remove()
    @model.bind 'change', => @render()
  events: 'click': -> window.app.createChannel(@model.get('id'))
  render: ->
    $(@el).detach().html(@template @model.toJSON())
    if @model.get('online')
      $(app.usersView.el).find('> ul').prepend(@el)
    else
      $(app.usersView.el).find('> ul').append(@el)
    $('.avatar').load -> $(@).addClass('avatar-wide') if @width > @height

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
  addUser: (user) =>
    (new UserView(model: user)).render() if user.get('id') isnt app.user.id
    $('.avatar').load -> $(@).addClass('avatar-wide') if @width > @height
  render: =>
    $(@el).find('> ul').empty()
    @collection.each (u) => @addUser(u)
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
  initialize: -> @model.bind('change', @render, @)
  render: -> $(@el).html(@template @model.toJSON())

class ChatView extends Backbone.View
  tagName: 'li'
  className: 'chat-window'
  template: _.template $('#chat').html()
  initialize: ->
    @user = app.getUser(@options.dest)
    @collection.bind('add', @addMessage)
    @collection.bind('all', @show)
    @user.bind('change:online', @updateStatus)
    $('.chat-windows').append($(@el).html(@template(user: @user)))
    $(@el).find('.helpmsg').text("#{@user.get('name')} is offline. He/She will receive your messages on his/her next connection.").show() unless @user.get('online')
    $(@el).find('.prompt').focus()
  events:
    'submit form': 'sendMessage'
    'click header': 'toggle'
    'click .close': -> $(@el).hide(); false
  unreadMsg: 0
  addMessage: (msg) => $(@el).find('.messages').append((new MessageView model: msg).render())
  updateStatus: =>
    if @user.get('online')
      $(@el).find('.helpmsg').text("#{@user.get('name')} went online").hide().fadeIn()
      $(@el).find('.online-status').show()
    else
      $(@el).find('.helpmsg').text("#{@user.get('name')} went offline").hide().fadeIn()
      $(@el).find('.online-status').hide()
  sendMessage: (e) =>
    e.preventDefault()
    input = $(@el).find('.prompt').val()
    if input
      $(@el).find('.helpmsg').hide()
      m = {from: localStorage['uid'], to: @options.dest, msg: input}
      app.socket.emit 'pm', JSON.stringify(m)
    $(@el).find('.prompt').val('')
  show: =>
    $(@el).show().find('.messages').scrollTop(99999).find('.prompt').focus()
    $(@el).find('.unreadMsg').text(++@unreadMsg).show() if $(@el).hasClass('folded')
  toggle: => if $(@el).hasClass('folded') then @unfold() else @fold()
  unfold: =>
    $(@el).animate { height: '350px', 'margin-top': '0' }, complete: =>
      $(@el).removeClass('folded').find('.unreadMsg').hide()
      $(@el).find('.prompt').focus()
    $(@el).find('.helpmsg').text("#{@user.get('name')} is offline. He/She will receive your messages on his/her next connection.").show() unless @user.get('online')
    @unreadMsg = 0; @
  fold: =>
    $(@el).animate({ height: '25px', 'margin-top': '325px' }, { complete: => $(@el).addClass('folded') }); @

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
    count = (@collection.filter (u) -> u.get('online') and u.get('id') isnt app.user.id).length
    $(@el).html(@template(usercount: count))
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

class ConversationLineView extends Backbone.View
  tagName: 'li'
  className: 'conversation-line'
  template: _.template $('#conversation-line').html()
  initialize: -> @model.bind('change', @render, @)
  render: -> $(@el).html(@template @model.toJSON())

class ConversationView extends Backbone.View
  tagName: 'ul'
  initialize: =>
    @collection.bind('add', @addLine)
    @collection.bind('reset', @render)
  addLine: (line) =>
    $(@el).append((new ConversationLineView model: line).render())
    $('.conversation').scrollTop(99999)
  render: =>
    $('.conversation').html(@el)
    @collection.each (line) => @addLine(line)

class InboxLineView extends Backbone.View
  tagName: 'li'
  className: 'inbox-line'
  template: _.template $('#inbox-line').html()
  initialize: -> @model.bind('change', @render)
  events: 'click': 'activate'
  render: -> $(@el).html(@template @model.toJSON())
  activate: =>
    $(@el).addClass('inboxline-active')
    app.inboxView.activate(@model.get('uid'))

class InboxView extends Backbone.View
  tagName: 'ul'
  initialize: =>
    @collection.bind('add', @addLine)
    @collection.bind('reset', @render)
    $('.inbox').html(@el)
    app.socket.emit('getLastMessages')
  addLine: (line) => $(@el).append((new InboxLineView model: line).render())
  render: =>
    $(@el).empty()
    @collection.each (line) => @addLine(line)
    @activate(@collection.last().get('uid'))

  activate: (uid) ->
    $('.inboxline-active').removeClass('inboxline-active')
    $('.conversation > ul').empty()
    app.conversation.selectedConversation = uid
    app.socket.emit('getMessageLog', uid)

class InboxMenuView extends Backbone.View
  tagName: 'li'
  template: _.template $('#inbox-menu').html()
  initialize: ->
    #@collection.bind('all', @render)
    $('.nav.pull-right').prepend(@el)
    @render()
  events: 'click': 'toggle'
  render: =>
    #count = (@collection.filter (m) -> m.get('online') and m.get('id') isnt app.user.id).length
    $(@el).html(@template(messagecount: 0))
  toggle: =>
    $(@el).toggleClass('active')
    $('.main').toggle()
    return false

class ChatApp
  constructor: ->
    @users = new Backbone.Collection()
    @inbox = new Backbone.Collection()
    @conversation = new Backbone.Collection()
    @socket = io.connect('/')
    @socket.on "error", (err) -> console.log err
    @socket.on "connected", (data) =>
      @user = data.user
      localStorage['uid'] = @user.id
      @usersView = new UsersView(collection: @users)
      @chatmenuView = new ChatMenuView(collection: @users)
      @ConversationView = new ConversationView(collection: @conversation)
      @inboxView = new InboxView(collection: @inbox)
      @inboxmenuView = new InboxMenuView(collection: @inbox)
      $('.user-box').text(@user.name)
      $('.user-box').parent().prepend("<div class='clip'><img src='/img/avatar/#{@user.id}.jpeg' class='avatar' /></div>")
      $('.avatar').load -> $(@).addClass('avatar-wide') if @width > @height
      $('.login').fadeOut()
      $('.openerp').fadeIn()
      @users.reset(u for u in data.users)
    if localStorage['uid']?
      $('.openerp').fadeIn()
      @socket.emit "logged", uid: localStorage['uid']
    else
      $('.login').fadeIn()
    @socket.on "connect", (id) => @users.each (u) -> u.set('online', true) if u.get('id') is id
    @socket.on "disconnect", (id) => @users.each (u) -> u.set('online', false) if u.get('id') is id
    @socket.on "pm", (data) =>
      dest = if data.from is @user.id then data.to else data.from
      @createChannel(dest) unless @channels[dest]?
      uid = app.conversation.selectedConversation
      data.time = new Date(data.time)
      @conversation.add(data) if uid is data.from or uid is data.to
      @channels[dest].addMessage(data)
      unless document.hasFocus()
        document.title = "(#{++@unreadMsg}) OpenERP"
        document.getElementById("ting").play()
    @socket.on "messageLog", (data) =>
      d.time = new Date(d.time) for d in data.msgs
      @conversation.reset(data.msgs)
    @socket.on "lastMessages", (data) =>
      d.time = new Date(d.time) for d in data
      @inbox.reset(data.sort((a, b) -> b.time - a.time))

    $(window).focus => document.title = "OpenERP"; @unreadMsg = 0
  channels: {}
  unreadMsg: 0
  createChannel: (dest) =>
    if @channels[dest]?
      @channels[dest].chatView.unfold().show()
    else
      @channels[dest] = new Channel(dest)
  login: (login, password) -> @socket.emit "login", { login: login, pwd: password }
  getUser: (uid) => user = @users.find (u) -> u.get('id') is uid

$ ->
  window.app = new ChatApp
  $('.login').submit (e) ->
    e.preventDefault()
    app.login $("input[name='login']").val(), $("input[name='password']").val()
  $('#logout').click (e) -> delete localStorage['uid']; location.reload()

