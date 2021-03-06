(function() {
  var Channel, ChatApp, ChatMenuView, ChatView, ConversationLineView, ConversationView, InboxLineView, InboxMenuView, InboxView, MessageView, Messages, UserView, UsersView,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; },
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  UserView = (function(_super) {

    __extends(UserView, _super);

    function UserView() {
      UserView.__super__.constructor.apply(this, arguments);
    }

    UserView.prototype.tagName = 'li';

    UserView.prototype.className = 'clearfix';

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
        return window.app.createChannel(this.model.get('id'));
      }
    };

    UserView.prototype.render = function() {
      $(this.el).detach().html(this.template(this.model.toJSON()));
      if (this.model.get('online')) {
        $(app.usersView.el).find('> ul').prepend(this.el);
      } else {
        $(app.usersView.el).find('> ul').append(this.el);
      }
      return $('.avatar').load(function() {
        if (this.width > this.height) return $(this).addClass('avatar-wide');
      });
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
      if (user.get('id') !== app.user.id) {
        (new UserView({
          model: user
        })).render();
      }
      return $('.avatar').load(function() {
        if (this.width > this.height) return $(this).addClass('avatar-wide');
      });
    };

    UsersView.prototype.render = function() {
      var _this = this;
      $(this.el).find('> ul').empty();
      return this.collection.each(function(u) {
        return _this.addUser(u);
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
      MessageView.__super__.constructor.apply(this, arguments);
    }

    MessageView.prototype.tagName = 'li';

    MessageView.prototype.className = 'msg';

    MessageView.prototype.template = _.template($('#chat-message').html());

    MessageView.prototype.initialize = function() {
      return this.model.bind('change', this.render, this);
    };

    MessageView.prototype.render = function() {
      return $(this.el).html(this.template(this.model.toJSON()));
    };

    return MessageView;

  })(Backbone.View);

  ChatView = (function(_super) {

    __extends(ChatView, _super);

    function ChatView() {
      this.fold = __bind(this.fold, this);
      this.unfold = __bind(this.unfold, this);
      this.toggle = __bind(this.toggle, this);
      this.show = __bind(this.show, this);
      this.sendMessage = __bind(this.sendMessage, this);
      this.updateStatus = __bind(this.updateStatus, this);
      this.addMessage = __bind(this.addMessage, this);
      ChatView.__super__.constructor.apply(this, arguments);
    }

    ChatView.prototype.tagName = 'li';

    ChatView.prototype.className = 'chat-window';

    ChatView.prototype.template = _.template($('#chat').html());

    ChatView.prototype.initialize = function() {
      this.user = app.getUser(this.options.dest);
      this.collection.bind('add', this.addMessage);
      this.collection.bind('all', this.show);
      this.user.bind('change:online', this.updateStatus);
      $('.chat-windows').append($(this.el).html(this.template({
        user: this.user
      })));
      if (!this.user.get('online')) {
        $(this.el).find('.helpmsg').text("" + (this.user.get('name')) + " is offline. He/She will receive your messages on his/her next connection.").show();
      }
      return $(this.el).find('.prompt').focus();
    };

    ChatView.prototype.events = {
      'submit form': 'sendMessage',
      'click header': 'toggle',
      'click .close': function() {
        $(this.el).hide();
        return false;
      }
    };

    ChatView.prototype.unreadMsg = 0;

    ChatView.prototype.addMessage = function(msg) {
      return $(this.el).find('.messages').append((new MessageView({
        model: msg
      })).render());
    };

    ChatView.prototype.updateStatus = function() {
      if (this.user.get('online')) {
        $(this.el).find('.helpmsg').text("" + (this.user.get('name')) + " went online").hide().fadeIn();
        return $(this.el).find('.online-status').show();
      } else {
        $(this.el).find('.helpmsg').text("" + (this.user.get('name')) + " went offline").hide().fadeIn();
        return $(this.el).find('.online-status').hide();
      }
    };

    ChatView.prototype.sendMessage = function(e) {
      var input, m;
      e.preventDefault();
      input = $(this.el).find('.prompt').val();
      if (input) {
        $(this.el).find('.helpmsg').hide();
        m = {
          from: localStorage['uid'],
          to: this.options.dest,
          msg: input
        };
        app.socket.emit('pm', JSON.stringify(m));
      }
      return $(this.el).find('.prompt').val('');
    };

    ChatView.prototype.show = function() {
      $(this.el).show().find('.messages').scrollTop(99999).find('.prompt').focus();
      if ($(this.el).hasClass('folded')) {
        return $(this.el).find('.unreadMsg').text(++this.unreadMsg).show();
      }
    };

    ChatView.prototype.toggle = function() {
      if ($(this.el).hasClass('folded')) {
        return this.unfold();
      } else {
        return this.fold();
      }
    };

    ChatView.prototype.unfold = function() {
      var _this = this;
      $(this.el).animate({
        height: '350px',
        'margin-top': '0'
      }, {
        complete: function() {
          $(_this.el).removeClass('folded').find('.unreadMsg').hide();
          return $(_this.el).find('.prompt').focus();
        }
      });
      if (!this.user.get('online')) {
        $(this.el).find('.helpmsg').text("" + (this.user.get('name')) + " is offline. He/She will receive your messages on his/her next connection.").show();
      }
      this.unreadMsg = 0;
      return this;
    };

    ChatView.prototype.fold = function() {
      var _this = this;
      $(this.el).animate({
        height: '25px',
        'margin-top': '325px'
      }, {
        complete: function() {
          return $(_this.el).addClass('folded');
        }
      });
      return this;
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
      var count;
      count = (this.collection.filter(function(u) {
        return u.get('online') && u.get('id') !== app.user.id;
      })).length;
      return $(this.el).html(this.template({
        usercount: count
      }));
    };

    ChatMenuView.prototype.toggle = function() {
      var offset;
      $(this.el).toggleClass('active');
      offset = $(this.el).hasClass('active') ? 0 : -220;
      $('.chatapp').animate({
        right: offset
      });
      $('.chat-windows').animate({
        right: offset + 220
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

  ConversationLineView = (function(_super) {

    __extends(ConversationLineView, _super);

    function ConversationLineView() {
      ConversationLineView.__super__.constructor.apply(this, arguments);
    }

    ConversationLineView.prototype.tagName = 'li';

    ConversationLineView.prototype.className = 'conversation-line';

    ConversationLineView.prototype.template = _.template($('#conversation-line').html());

    ConversationLineView.prototype.initialize = function() {
      return this.model.bind('change', this.render, this);
    };

    ConversationLineView.prototype.render = function() {
      return $(this.el).html(this.template(this.model.toJSON()));
    };

    return ConversationLineView;

  })(Backbone.View);

  ConversationView = (function(_super) {

    __extends(ConversationView, _super);

    function ConversationView() {
      this.render = __bind(this.render, this);
      this.addLine = __bind(this.addLine, this);
      this.initialize = __bind(this.initialize, this);
      ConversationView.__super__.constructor.apply(this, arguments);
    }

    ConversationView.prototype.tagName = 'ul';

    ConversationView.prototype.initialize = function() {
      this.collection.bind('add', this.addLine);
      return this.collection.bind('reset', this.render);
    };

    ConversationView.prototype.addLine = function(line) {
      $(this.el).append((new ConversationLineView({
        model: line
      })).render());
      return $('.conversation').scrollTop(99999);
    };

    ConversationView.prototype.render = function() {
      var _this = this;
      $('.conversation').html(this.el);
      return this.collection.each(function(line) {
        return _this.addLine(line);
      });
    };

    return ConversationView;

  })(Backbone.View);

  InboxLineView = (function(_super) {

    __extends(InboxLineView, _super);

    function InboxLineView() {
      this.activate = __bind(this.activate, this);
      InboxLineView.__super__.constructor.apply(this, arguments);
    }

    InboxLineView.prototype.tagName = 'li';

    InboxLineView.prototype.className = 'inbox-line';

    InboxLineView.prototype.template = _.template($('#inbox-line').html());

    InboxLineView.prototype.initialize = function() {
      return this.model.bind('change', this.render);
    };

    InboxLineView.prototype.events = {
      'click': 'activate'
    };

    InboxLineView.prototype.render = function() {
      return $(this.el).html(this.template(this.model.toJSON()));
    };

    InboxLineView.prototype.activate = function() {
      $(this.el).addClass('inboxline-active');
      return app.inboxView.activate(this.model.get('uid'));
    };

    return InboxLineView;

  })(Backbone.View);

  InboxView = (function(_super) {

    __extends(InboxView, _super);

    function InboxView() {
      this.render = __bind(this.render, this);
      this.addLine = __bind(this.addLine, this);
      this.initialize = __bind(this.initialize, this);
      InboxView.__super__.constructor.apply(this, arguments);
    }

    InboxView.prototype.tagName = 'ul';

    InboxView.prototype.initialize = function() {
      this.collection.bind('add', this.addLine);
      this.collection.bind('reset', this.render);
      $('.inbox').html(this.el);
      return app.socket.emit('getLastMessages');
    };

    InboxView.prototype.addLine = function(line) {
      return $(this.el).append((new InboxLineView({
        model: line
      })).render());
    };

    InboxView.prototype.render = function() {
      var _this = this;
      $(this.el).empty();
      this.collection.each(function(line) {
        return _this.addLine(line);
      });
      return this.activate(this.collection.last().get('uid'));
    };

    InboxView.prototype.activate = function(uid) {
      $('.inboxline-active').removeClass('inboxline-active');
      $('.conversation > ul').empty();
      app.conversation.selectedConversation = uid;
      return app.socket.emit('getMessageLog', uid);
    };

    return InboxView;

  })(Backbone.View);

  InboxMenuView = (function(_super) {

    __extends(InboxMenuView, _super);

    function InboxMenuView() {
      this.toggle = __bind(this.toggle, this);
      this.render = __bind(this.render, this);
      InboxMenuView.__super__.constructor.apply(this, arguments);
    }

    InboxMenuView.prototype.tagName = 'li';

    InboxMenuView.prototype.template = _.template($('#inbox-menu').html());

    InboxMenuView.prototype.initialize = function() {
      $('.nav.pull-right').prepend(this.el);
      return this.render();
    };

    InboxMenuView.prototype.events = {
      'click': 'toggle'
    };

    InboxMenuView.prototype.render = function() {
      return $(this.el).html(this.template({
        messagecount: 0
      }));
    };

    InboxMenuView.prototype.toggle = function() {
      $(this.el).toggleClass('active');
      $('.main').toggle();
      return false;
    };

    return InboxMenuView;

  })(Backbone.View);

  ChatApp = (function() {

    function ChatApp() {
      this.getUser = __bind(this.getUser, this);
      this.createChannel = __bind(this.createChannel, this);
      var _this = this;
      this.users = new Backbone.Collection();
      this.inbox = new Backbone.Collection();
      this.conversation = new Backbone.Collection();
      this.socket = io.connect('/');
      this.socket.on("error", function(err) {
        return console.log(err);
      });
      this.socket.on("connected", function(data) {
        var u;
        _this.user = data.user;
        localStorage['uid'] = _this.user.id;
        _this.usersView = new UsersView({
          collection: _this.users
        });
        _this.chatmenuView = new ChatMenuView({
          collection: _this.users
        });
        _this.ConversationView = new ConversationView({
          collection: _this.conversation
        });
        _this.inboxView = new InboxView({
          collection: _this.inbox
        });
        _this.inboxmenuView = new InboxMenuView({
          collection: _this.inbox
        });
        $('.user-box').text(_this.user.name);
        $('.user-box').parent().prepend("<div class='clip'><img src='/img/avatar/" + _this.user.id + ".jpeg' class='avatar' /></div>");
        $('.avatar').load(function() {
          if (this.width > this.height) return $(this).addClass('avatar-wide');
        });
        $('.login').fadeOut();
        $('.openerp').fadeIn();
        return _this.users.reset((function() {
          var _i, _len, _ref, _results;
          _ref = data.users;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            u = _ref[_i];
            _results.push(u);
          }
          return _results;
        })());
      });
      if (localStorage['uid'] != null) {
        $('.openerp').fadeIn();
        this.socket.emit("logged", {
          uid: localStorage['uid']
        });
      } else {
        $('.login').fadeIn();
      }
      this.socket.on("connect", function(id) {
        return _this.users.each(function(u) {
          if (u.get('id') === id) return u.set('online', true);
        });
      });
      this.socket.on("disconnect", function(id) {
        return _this.users.each(function(u) {
          if (u.get('id') === id) return u.set('online', false);
        });
      });
      this.socket.on("pm", function(data) {
        var dest, uid;
        dest = data.from === _this.user.id ? data.to : data.from;
        if (_this.channels[dest] == null) _this.createChannel(dest);
        uid = app.conversation.selectedConversation;
        data.time = new Date(data.time);
        if (uid === data.from || uid === data.to) _this.conversation.add(data);
        _this.channels[dest].addMessage(data);
        if (!document.hasFocus()) {
          document.title = "(" + (++_this.unreadMsg) + ") OpenERP";
          return document.getElementById("ting").play();
        }
      });
      this.socket.on("messageLog", function(data) {
        var d, _i, _len, _ref;
        _ref = data.msgs;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          d = _ref[_i];
          d.time = new Date(d.time);
        }
        return _this.conversation.reset(data.msgs);
      });
      this.socket.on("lastMessages", function(data) {
        var d, _i, _len;
        for (_i = 0, _len = data.length; _i < _len; _i++) {
          d = data[_i];
          d.time = new Date(d.time);
        }
        return _this.inbox.reset(data.sort(function(a, b) {
          return b.time - a.time;
        }));
      });
      $(window).focus(function() {
        document.title = "OpenERP";
        return _this.unreadMsg = 0;
      });
    }

    ChatApp.prototype.channels = {};

    ChatApp.prototype.unreadMsg = 0;

    ChatApp.prototype.createChannel = function(dest) {
      if (this.channels[dest] != null) {
        return this.channels[dest].chatView.unfold().show();
      } else {
        return this.channels[dest] = new Channel(dest);
      }
    };

    ChatApp.prototype.login = function(login, password) {
      return this.socket.emit("login", {
        login: login,
        pwd: password
      });
    };

    ChatApp.prototype.getUser = function(uid) {
      var user;
      return user = this.users.find(function(u) {
        return u.get('id') === uid;
      });
    };

    return ChatApp;

  })();

  $(function() {
    window.app = new ChatApp;
    $('.login').submit(function(e) {
      e.preventDefault();
      return app.login($("input[name='login']").val(), $("input[name='password']").val());
    });
    return $('#logout').click(function(e) {
      delete localStorage['uid'];
      return location.reload();
    });
  });

}).call(this);
