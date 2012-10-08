(function() {
  var Channel, ChatApp, ChatMenuView, ChatView, MessageView, Messages, UserView, UsersView,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; },
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  UserView = (function(_super) {

    __extends(UserView, _super);

    function UserView() {
      UserView.__super__.constructor.apply(this, arguments);
    }

    UserView.prototype.tagName = 'li';

    UserView.prototype.className = 'user';

    UserView.prototype.template = _.template($('#chat-user').html());

    UserView.prototype.initialize = function() {
      var _this = this;
      this.model.bind('remove', function() {
        return $(_this.el).remove();
      });
      return this.model.bind('change', function() {
        return _this.render();
      });
    };

    UserView.prototype.events = {
      'click': function() {
        return window.app.createChannel(this.model.get('name'));
      }
    };

    UserView.prototype.render = function() {
      return $(this.el).html(this.template(this.model.toJSON()));
    };

    return UserView;

  })(Backbone.View);

  UsersView = (function(_super) {

    __extends(UsersView, _super);

    function UsersView() {
      this.searchclear = __bind(this.searchclear, this);
      this.filter = __bind(this.filter, this);
      this.render = __bind(this.render, this);
      this.addUser = __bind(this.addUser, this);
      UsersView.__super__.constructor.apply(this, arguments);
    }

    UsersView.prototype.className = 'users';

    UsersView.prototype.template = _.template($('#user-list').html());

    UsersView.prototype.initialize = function() {
      this.collection.bind('add', this.addUser);
      this.collection.bind('reset', this.render);
      $('.chatapp').append($(this.el).html(this.template({})));
      return this.render();
    };

    UsersView.prototype.events = {
      'keyup .searchbox': 'filter',
      'click .searchclear': 'searchclear'
    };

    UsersView.prototype.addUser = function(user) {
      return $(this.el).find('> ul').append((new UserView({
        model: user
      })).render());
    };

    UsersView.prototype.render = function() {
      var _this = this;
      $(this.el).find('> ul').empty();
      return this.collection.each(function(user) {
        return _this.addUser(user);
      });
    };

    UsersView.prototype.filter = function() {
      var s, u, _i, _len, _ref;
      s = $('.searchbox').val().toLowerCase();
      if (s) {
        $(this.el).find('> ul').empty();
        _ref = this.collection.filter(function(u) {
          return ~u.get('name').toLowerCase().indexOf(s);
        });
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          u = _ref[_i];
          this.addUser(u);
        }
        return $('.searchclear').fadeIn('fast');
      } else {
        return this.searchclear();
      }
    };

    UsersView.prototype.searchclear = function() {
      $('.searchclear').fadeOut('fast');
      $('.searchbox').val('').focus();
      return this.render();
    };

    return UsersView;

  })(Backbone.View);

  Messages = (function(_super) {

    __extends(Messages, _super);

    function Messages() {
      Messages.__super__.constructor.apply(this, arguments);
    }

    Messages.prototype.add = function(msg) {
      var m;
      m = this.last();
      if ((m != null) && m.get('from') === msg.from) {
        m.get('messages').push(msg);
        return m.trigger("change");
      } else {
        return Messages.__super__.add.call(this, {
          from: msg.from,
          to: msg.to,
          messages: [msg]
        });
      }
    };

    return Messages;

  })(Backbone.Collection);

  MessageView = (function(_super) {

    __extends(MessageView, _super);

    function MessageView() {
      this.render = __bind(this.render, this);
      MessageView.__super__.constructor.apply(this, arguments);
    }

    MessageView.prototype.tagName = 'li';

    MessageView.prototype.className = 'msg';

    MessageView.prototype.template = _.template($('#chat-message').html());

    MessageView.prototype.initialize = function() {
      return this.model.bind('change', this.render);
    };

    MessageView.prototype.render = function() {
      return $(this.el).html(this.template(this.model.toJSON()));
    };

    return MessageView;

  })(Backbone.View);

  ChatView = (function(_super) {

    __extends(ChatView, _super);

    function ChatView() {
      this.toggle = __bind(this.toggle, this);
      this.show = __bind(this.show, this);
      this.sendMessage = __bind(this.sendMessage, this);
      this.addMessage = __bind(this.addMessage, this);
      ChatView.__super__.constructor.apply(this, arguments);
    }

    ChatView.prototype.tagName = 'li';

    ChatView.prototype.className = 'chat-window';

    ChatView.prototype.template = _.template($('#chat').html());

    ChatView.prototype.initialize = function() {
      this.collection.bind('add', this.addMessage);
      this.collection.bind('all', this.show);
      $('.chat-windows').append($(this.el).html(this.template({
        title: this.options.dest
      })));
      return $('.prompt').focus();
    };

    ChatView.prototype.events = {
      'submit form': 'sendMessage',
      'click header': 'toggle',
      'click .close': function() {
        $(this.el).hide();
        return this.toggle();
      }
    };

    ChatView.prototype.unreadMsg = 0;

    ChatView.prototype.addMessage = function(msg) {
      return $(this.el).find('.messages').append((new MessageView({
        model: msg
      })).render());
    };

    ChatView.prototype.sendMessage = function(e) {
      var input, m;
      e.preventDefault();
      input = $(this.el).find('.prompt').val();
      if (input) {
        m = {
          from: localStorage['name'],
          to: this.options.dest,
          msg: input,
          time: new Date()
        };
        app.socket.emit('pm', JSON.stringify(m));
        this.collection.add(m);
      }
      return $(this.el).find('.prompt').val('');
    };

    ChatView.prototype.show = function() {
      $(this.el).show().find('.messages').scrollTop(99999);
      $('.prompt').focus();
      if ($(this.el).hasClass('folded')) {
        return $(this.el).find('.unreadMsg').text(++this.unreadMsg).show();
      }
    };

    ChatView.prototype.toggle = function() {
      var _this = this;
      if ($(this.el).hasClass('folded')) {
        $(this.el).animate({
          height: '380px'
        }, {
          complete: function() {
            $(_this.el).removeClass('folded').find('.unreadMsg').hide();
            return $('.prompt').focus();
          }
        });
        return this.unreadMsg = 0;
      } else {
        return $(this.el).animate({
          height: '25px'
        }, {
          complete: function() {
            return $(_this.el).addClass('folded');
          }
        });
      }
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

    ChatMenuView.prototype.className = 'active';

    ChatMenuView.prototype.template = _.template($('#chat-menu').html());

    ChatMenuView.prototype.initialize = function() {
      this.collection.bind('all', this.render);
      $('.nav.pull-right').prepend(this.el);
      return this.render();
    };

    ChatMenuView.prototype.events = {
      'click': 'toggle'
    };

    ChatMenuView.prototype.render = function() {
      return $(this.el).html(this.template({
        usercount: (this.collection.filter(function(u) {
          return u.get('online');
        })).length
      }));
    };

    ChatMenuView.prototype.toggle = function() {
      var offset;
      $(this.el).toggleClass('active');
      offset = $(this.el).hasClass('active') ? 0 : -210;
      $('.chatapp').animate({
        right: offset
      });
      $('.chat-windows').animate({
        right: offset + 210
      });
      return false;
    };

    return ChatMenuView;

  })(Backbone.View);

  Channel = (function() {

    function Channel(dest) {
      this.dest = dest;
      this.messages = new Messages;
      this.chatView = new ChatView({
        collection: this.messages,
        dest: this.dest
      });
    }

    Channel.prototype.addMessage = function(msg) {
      msg.time = new Date(msg.time);
      return this.messages.add(msg);
    };

    return Channel;

  })();

  ChatApp = (function() {

    function ChatApp() {
      this.login = __bind(this.login, this);
      this.createChannel = __bind(this.createChannel, this);      this.instance = openerp.init([]);
      openerp.web.corelib(this.instance);
      openerp.web.coresetup(this.instance);
      openerp.web.data(this.instance);
      this.instance.session.session_bind('http://localhost:8069');
    }

    ChatApp.prototype.channels = {};

    ChatApp.prototype.createChannel = function(dest) {
      if (this.channels[dest] != null) {
        return this.channels[dest].chatView.show();
      } else {
        return this.channels[dest] = new Channel(dest);
      }
    };

    ChatApp.prototype.login = function(db, login, password) {
      var _this = this;
      return this.instance.session.session_authenticate(db, login, password, false).then(function() {
        var Users;
        Users = new instance.web.Model('res.users');
        return Users.query(['name', 'login', 'image']).all().then(function(users) {
          var u, _i, _len;
          _this.currentUser = _(users).find(function(u) {
            return u.login === login;
          });
          for (_i = 0, _len = users.length; _i < _len; _i++) {
            u = users[_i];
            if (u.id !== _this.currentUsers.id) {
              users = {
                id: u.id,
                name: u.name,
                image: u.image
              };
            }
          }
          _this.users = new Backbone.Collection(users);
          _this.usersView = new UsersView({
            collection: _this.users
          });
          _this.chatmenuView = new ChatMenuView({
            collection: _this.users
          });
          _this.socket = io.connect('/');
          _this.socket.emit("connect", localStorage['name']);
          _this.socket.on("connect", function(id) {
            return _this.users.each(function(u) {
              if (u.get('id') === id) return u.set('online', true);
            });
          });
          _this.socket.on("disconnect", function(id) {
            return _this.users.each(function(u) {
              if (u.get('id') === id) return u.set('online', false);
            });
          });
          return _this.socket.on("pm", function(data) {
            if (_this.channels[data.from] == null) _this.createChannel(data.from);
            return _this.channels[data.from].addMessage(data);
          });
        });
      });
    };

    return ChatApp;

  })();

  $(function() {
    window.app = new ChatApp;
    $('.login').submit(function(e) {
      e.preventDefault();
      return app.login('foobar', $("input[name='login']").val(), $("input[name='password']").val());
    });
    return $('#change-name .save').click(function() {
      $('.user-box').text($('#change-name input').val());
      return localStorage['name'] = $('#change-name input').val();
    });
  });

}).call(this);
