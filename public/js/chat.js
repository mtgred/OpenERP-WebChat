(function() {
  var Chat, ChatApp, ChatMenuView, ChatView, MessageView, User, UserView, UsersView,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; },
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  User = (function(_super) {

    __extends(User, _super);

    function User() {
      User.__super__.constructor.apply(this, arguments);
    }

    return User;

  })(Backbone.Model);

  UserView = (function(_super) {

    __extends(UserView, _super);

    function UserView() {
      UserView.__super__.constructor.apply(this, arguments);
    }

    UserView.prototype.tagName = 'li';

    UserView.prototype.className = 'user';

    UserView.prototype.initialize = function() {
      var _this = this;
      return this.model.bind('remove', function() {
        return $(_this.el).remove();
      });
    };

    UserView.prototype.template = _.template($('#chat-user').html());

    UserView.prototype.render = function() {
      return $(this.el).html(this.template(this.model.toJSON()));
    };

    return UserView;

  })(Backbone.View);

  UsersView = (function(_super) {

    __extends(UsersView, _super);

    function UsersView() {
      this.addUser = __bind(this.addUser, this);
      UsersView.__super__.constructor.apply(this, arguments);
    }

    UsersView.prototype.className = 'users';

    UsersView.prototype.template = _.template($('#user-list').html());

    UsersView.prototype.initialize = function() {
      this.collection.bind('add', this.addUser);
      return $('.chatapp').append($(this.el).html(this.template({})));
    };

    UsersView.prototype.addUser = function(user) {
      return $(this.el).find('> ul').append((new UserView({
        model: user
      })).render());
    };

    return UsersView;

  })(Backbone.View);

  MessageView = (function(_super) {

    __extends(MessageView, _super);

    function MessageView() {
      MessageView.__super__.constructor.apply(this, arguments);
    }

    MessageView.prototype.tagName = 'li';

    MessageView.prototype.className = 'msg';

    MessageView.prototype.template = _.template($('#chat-message').html());

    MessageView.prototype.render = function() {
      return $(this.el).html(this.template(this.model.toJSON()));
    };

    return MessageView;

  })(Backbone.View);

  ChatView = (function(_super) {

    __extends(ChatView, _super);

    function ChatView() {
      this.close = __bind(this.close, this);
      this.sendMessage = __bind(this.sendMessage, this);
      this.addMessage = __bind(this.addMessage, this);
      ChatView.__super__.constructor.apply(this, arguments);
    }

    ChatView.prototype.className = 'chatview';

    ChatView.prototype.template = _.template($('#chat').html());

    ChatView.prototype.initialize = function() {
      this.collection.bind('add', this.addMessage);
      return $('.chat-window').append($(this.el).html(this.template({
        title: 'Foobar'
      })));
    };

    ChatView.prototype.events = {
      'submit form': 'sendMessage',
      'click .close': 'close'
    };

    ChatView.prototype.addMessage = function(msg) {
      return $(this.el).find('.messages > ul').append((new MessageView({
        model: msg
      })).render()).parent().scrollTop(99999);
    };

    ChatView.prototype.sendMessage = function(e) {
      var input;
      input = $(this.el).find('.prompt').val();
      if (input) {
        chatapp.socket.send(JSON.stringify({
          username: localStorage['username'],
          msg: input
        }));
        this.collection.add({
          username: localStorage['username'],
          msg: input
        });
      }
      $(this.el).find('.prompt').val('');
      return false;
    };

    ChatView.prototype.close = function() {
      return $(this.el).hide();
    };

    return ChatView;

  })(Backbone.View);

  ChatMenuView = (function(_super) {

    __extends(ChatMenuView, _super);

    function ChatMenuView() {
      this.toggle = __bind(this.toggle, this);
      this.render = __bind(this.render, this);
      ChatMenuView.__super__.constructor.apply(this, arguments);
    }

    ChatMenuView.prototype.tagName = 'li';

    ChatMenuView.prototype.template = _.template($('#chat-menu').html());

    ChatMenuView.prototype.initialize = function() {
      this.collection.bind('add', this.render);
      this.collection.bind('remove', this.render);
      $('.nav.pull-right').prepend(this.el);
      return this.render();
    };

    ChatMenuView.prototype.events = {
      'click': 'toggle'
    };

    ChatMenuView.prototype.render = function() {
      return $(this.el).html(this.template({
        usercount: this.collection.length
      }));
    };

    ChatMenuView.prototype.toggle = function() {
      var offset;
      $(this.el).toggleClass('active');
      offset = $(this.el).hasClass('active') ? '0' : '-210';
      $('.chatapp').animate({
        right: offset
      });
      return false;
    };

    return ChatMenuView;

  })(Backbone.View);

  Chat = (function() {

    function Chat(title) {
      this.title = title;
      this.removeUser = __bind(this.removeUser, this);
      this.addUser = __bind(this.addUser, this);
      this.addMessage = __bind(this.addMessage, this);
      this.messages = new Backbone.Collection;
      this.users = new Backbone.Collection;
      this.usersView = new UsersView({
        collection: this.users
      });
      this.chatmenuView = new ChatMenuView({
        collection: this.users
      });
      this.chatView = new ChatView({
        collection: this.messages
      });
    }

    Chat.prototype.addMessage = function(msg) {
      return this.messages.add(msg);
    };

    Chat.prototype.addUser = function(username) {
      return this.users.add(new User({
        username: username
      }));
    };

    Chat.prototype.removeUser = function(username) {
      return this.users.each(function(user) {
        if (user.get('username') === username) return user.destroy();
      });
    };

    return Chat;

  })();

  ChatApp = (function() {

    function ChatApp() {
      var _this = this;
      this.socket = io.connect('/');
      this.socket.emit("join", localStorage["username"]);
      this.socket.on("join", function(username) {
        return _this.chats['general'].addUser(username);
      });
      this.socket.on("disconnect", function(username) {
        return _this.chats['general'].removeUser(username);
      });
      this.socket.on("close", function() {
        return alert('Connection lost');
      });
      this.socket.on("message", function(data) {
        return _this.chats['general'].addMessage(JSON.parse(data['msg']));
      });
      this.socket.on("userlist", function(userlist) {
        var k, v, _results;
        _results = [];
        for (k in userlist) {
          v = userlist[k];
          _results.push(_this.chats['general'].addUser(k));
        }
        return _results;
      });
    }

    ChatApp.prototype.chats = {
      general: new Chat('general')
    };

    return ChatApp;

  })();

  $(function() {
    if (!localStorage['username']) {
      localStorage['username'] = 'Guest ' + Math.floor(Math.random() * 1000);
    }
    $('.user-box').text(localStorage['username']);
    $('#change-name .save').click(function() {
      $('.user-box').text($('#change-name input').val());
      return localStorage['username'] = $('#change-name input').val();
    });
    return window.chatapp = new ChatApp;
  });

}).call(this);
