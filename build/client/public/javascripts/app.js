(function() {
  'use strict';

  var globals = typeof window === 'undefined' ? global : window;
  if (typeof globals.require === 'function') return;

  var modules = {};
  var cache = {};
  var has = ({}).hasOwnProperty;

  var aliases = {};

  var endsWith = function(str, suffix) {
    return str.indexOf(suffix, str.length - suffix.length) !== -1;
  };

  var unalias = function(alias, loaderPath) {
    var start = 0;
    if (loaderPath) {
      if (loaderPath.indexOf('components/' === 0)) {
        start = 'components/'.length;
      }
      if (loaderPath.indexOf('/', start) > 0) {
        loaderPath = loaderPath.substring(start, loaderPath.indexOf('/', start));
      }
    }
    var result = aliases[alias + '/index.js'] || aliases[loaderPath + '/deps/' + alias + '/index.js'];
    if (result) {
      return 'components/' + result.substring(0, result.length - '.js'.length);
    }
    return alias;
  };

  var expand = (function() {
    var reg = /^\.\.?(\/|$)/;
    return function(root, name) {
      var results = [], parts, part;
      parts = (reg.test(name) ? root + '/' + name : name).split('/');
      for (var i = 0, length = parts.length; i < length; i++) {
        part = parts[i];
        if (part === '..') {
          results.pop();
        } else if (part !== '.' && part !== '') {
          results.push(part);
        }
      }
      return results.join('/');
    };
  })();
  var dirname = function(path) {
    return path.split('/').slice(0, -1).join('/');
  };

  var localRequire = function(path) {
    return function(name) {
      var absolute = expand(dirname(path), name);
      return globals.require(absolute, path);
    };
  };

  var initModule = function(name, definition) {
    var module = {id: name, exports: {}};
    cache[name] = module;
    definition(module.exports, localRequire(name), module);
    return module.exports;
  };

  var require = function(name, loaderPath) {
    var path = expand(name, '.');
    if (loaderPath == null) loaderPath = '/';
    path = unalias(name, loaderPath);

    if (has.call(cache, path)) return cache[path].exports;
    if (has.call(modules, path)) return initModule(path, modules[path]);

    var dirIndex = expand(path, './index');
    if (has.call(cache, dirIndex)) return cache[dirIndex].exports;
    if (has.call(modules, dirIndex)) return initModule(dirIndex, modules[dirIndex]);

    throw new Error('Cannot find module "' + name + '" from '+ '"' + loaderPath + '"');
  };

  require.alias = function(from, to) {
    aliases[to] = from;
  };

  require.register = require.define = function(bundle, fn) {
    if (typeof bundle === 'object') {
      for (var key in bundle) {
        if (has.call(bundle, key)) {
          modules[key] = bundle[key];
        }
      }
    } else {
      modules[bundle] = fn;
    }
  };

  require.list = function() {
    var result = [];
    for (var item in modules) {
      if (has.call(modules, item)) {
        result.push(item);
      }
    }
    return result;
  };

  require.brunch = true;
  globals.require = require;
})();
require.register("initialize", function(exports, require, module) {
var Router;

Router = require('./router');

$(function() {
  var e, locale, locales, pathToSocketIO, polyglot, url;
  window.app = {};
  locale = window.locale;
  polyglot = new Polyglot();
  try {
    locales = require("locales/" + locale);
  } catch (_error) {
    e = _error;
    locale = 'en';
    locales = require('locales/en');
  }
  polyglot.extend(locales);
  window.t = polyglot.t.bind(polyglot);
  window.app.router = new Router();
  Backbone.history.start();
  url = window.location.origin;
  pathToSocketIO = "/" + (window.location.pathname.substring(1)) + "socket.io";
  return window.sio = io(url, {
    path: pathToSocketIO,
    reconnectionDelayMax: 60000,
    reconectionDelay: 2000,
    reconnectionAttempts: 3
  });
});

});

require.register("lib/app_helpers", function(exports, require, module) {
(function() {
  return (function() {
    var console, dummy, method, methods, _results;
    console = window.console = window.console || {};
    method = void 0;
    dummy = function() {};
    methods = 'assert,count,debug,dir,dirxml,error,exception, group,groupCollapsed,groupEnd,info,log,markTimeline, profile,profileEnd,time,timeEnd,trace,warn'.split(',');
    _results = [];
    while (method = methods.pop()) {
      _results.push(console[method] = console[method] || dummy);
    }
    return _results;
  })();
})();

});

require.register("lib/base_view", function(exports, require, module) {
var BaseView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

module.exports = BaseView = (function(_super) {
  __extends(BaseView, _super);

  function BaseView() {
    return BaseView.__super__.constructor.apply(this, arguments);
  }

  BaseView.prototype.template = function() {};

  BaseView.prototype.initialize = function() {};

  BaseView.prototype.getRenderData = function() {
    var _ref;
    return {
      model: (_ref = this.model) != null ? _ref.toJSON() : void 0
    };
  };

  BaseView.prototype.render = function() {
    this.beforeRender();
    this.$el.html(this.template(this.getRenderData()));
    this.afterRender();
    return this;
  };

  BaseView.prototype.beforeRender = function() {};

  BaseView.prototype.afterRender = function() {};

  BaseView.prototype.destroy = function() {
    this.undelegateEvents();
    this.$el.removeData().unbind();
    this.remove();
    return Backbone.View.prototype.remove.call(this);
  };

  return BaseView;

})(Backbone.View);

});

require.register("lib/view_collection", function(exports, require, module) {
var BaseView, ViewCollection,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

BaseView = require('lib/base_view');

module.exports = ViewCollection = (function(_super) {
  __extends(ViewCollection, _super);

  function ViewCollection() {
    this.removeItem = __bind(this.removeItem, this);
    this.addItem = __bind(this.addItem, this);
    return ViewCollection.__super__.constructor.apply(this, arguments);
  }

  ViewCollection.prototype.itemview = null;

  ViewCollection.prototype.views = {};

  ViewCollection.prototype.template = function() {
    return '';
  };

  ViewCollection.prototype.itemViewOptions = function() {};

  ViewCollection.prototype.collectionEl = null;

  ViewCollection.prototype.onChange = function() {
    return this.$el.toggleClass('empty', _.size(this.views) === 0);
  };

  ViewCollection.prototype.appendView = function(view) {
    return this.$collectionEl.append(view.el);
  };

  ViewCollection.prototype.initialize = function() {
    var collectionEl;
    ViewCollection.__super__.initialize.apply(this, arguments);
    this.views = {};
    this.listenTo(this.collection, "reset", this.onReset);
    this.listenTo(this.collection, "add", this.addItem);
    this.listenTo(this.collection, "remove", this.removeItem);
    if (this.collectionEl == null) {
      return collectionEl = el;
    }
  };

  ViewCollection.prototype.render = function() {
    var id, view, _ref;
    _ref = this.views;
    for (id in _ref) {
      view = _ref[id];
      view.$el.detach();
    }
    return ViewCollection.__super__.render.apply(this, arguments);
  };

  ViewCollection.prototype.afterRender = function() {
    var id, view, _ref;
    this.$collectionEl = $(this.collectionEl);
    _ref = this.views;
    for (id in _ref) {
      view = _ref[id];
      this.appendView(view.$el);
    }
    this.onReset(this.collection);
    return this.onChange(this.views);
  };

  ViewCollection.prototype.remove = function() {
    this.onReset([]);
    return ViewCollection.__super__.remove.apply(this, arguments);
  };

  ViewCollection.prototype.onReset = function(newcollection) {
    var id, view, _ref;
    _ref = this.views;
    for (id in _ref) {
      view = _ref[id];
      view.remove();
    }
    return newcollection.forEach(this.addItem);
  };

  ViewCollection.prototype.addItem = function(model) {
    var options, view;
    options = _.extend({}, {
      model: model
    }, this.itemViewOptions(model));
    view = new this.itemview(options);
    this.views[model.cid] = view.render();
    this.appendView(view);
    return this.onChange(this.views);
  };

  ViewCollection.prototype.removeItem = function(model) {
    this.views[model.cid].remove();
    delete this.views[model.cid];
    return this.onChange(this.views);
  };

  return ViewCollection;

})(BaseView);

});

require.register("locales/en", function(exports, require, module) {
module.exports = {
  "leave google title": "Leave Google",
  "leave google step1 title": "First, connect to your Google account.",
  "leave google email label": "Your Google email",
  "leave google email placeholder": "you@gmail.com",
  "leave google connect label": "Connect with Google",
  "leave google step2 title": "Then, copy and paste the code from the popup in this field:",
  "leave google choice title": "What data do you want tot import?",
  "leave google choice photo": "Photos",
  "leave google choice calendar": "Calendars",
  "leave google choice contact": "Contacts",
  "invalid token": "The token is invalid, please restart the process from the beginning."
};

});

require.register("router", function(exports, require, module) {
var FormView, LogView, Router, mainView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

FormView = require('views/leave_google_form');

LogView = require('views/leave_google_log');

mainView = null;

module.exports = Router = (function(_super) {
  __extends(Router, _super);

  function Router() {
    return Router.__super__.constructor.apply(this, arguments);
  }

  Router.prototype.routes = {
    '': 'main',
    'status': 'status'
  };

  Router.prototype.main = function() {
    if (mainView != null) {
      mainView.remove();
    }
    mainView = new FormView();
    mainView.render();
    return $('body').empty().append(mainView.$el);
  };

  Router.prototype.status = function() {
    if (mainView != null) {
      mainView.remove();
    }
    mainView = new LogView();
    mainView.render();
    return $('body').empty().append(mainView.$el);
  };

  return Router;

})(Backbone.Router);

});

require.register("views/leave_google_form", function(exports, require, module) {
var BaseView, LeaveGoogleView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

BaseView = require('../lib/base_view');

module.exports = LeaveGoogleView = (function(_super) {
  __extends(LeaveGoogleView, _super);

  function LeaveGoogleView() {
    return LeaveGoogleView.__super__.constructor.apply(this, arguments);
  }

  LeaveGoogleView.prototype.template = require('./templates/leave_google_form');

  LeaveGoogleView.prototype.tagName = 'section';

  LeaveGoogleView.prototype.id = 'leave-google';

  LeaveGoogleView.prototype.events = {
    'click  a#connect-google': 'connectWithGoogle',
    'keypress #auth_code': 'onAuthCodeKeypress',
    'click #step-pastecode-ok': 'onStep2Done',
    'click #step-pastecode-ko': 'onStep2Cancel',
    'click #lg-login': 'submitLg'
  };

  LeaveGoogleView.prototype.changeStep = function(step) {
    this.$('.step').hide();
    this.$("#step-" + step).show();
    if (step === 'pastecode') {
      return this.$('#auth_code').focus();
    }
  };

  LeaveGoogleView.prototype.afterRender = function() {
    return this.changeStep('bigbutton');
  };

  LeaveGoogleView.prototype.connectWithGoogle = function(event) {
    var opts;
    event.preventDefault();
    opts = ['toolbars=0', 'width=700', 'height=600', 'left=200', 'top=200', 'scrollbars=1', 'resizable=1'].join(',');
    this.popup = window.open(window.oauthUrl, 'Google OAuth', opts);
    return this.changeStep('pastecode');
  };

  LeaveGoogleView.prototype.onStep2Done = function(event) {
    var _ref;
    event.preventDefault();
    if ((_ref = this.popup) != null) {
      _ref.close();
    }
    return this.changeStep('pickscope');
  };

  LeaveGoogleView.prototype.onStep2Cancel = function(event) {
    var _ref;
    event.preventDefault();
    if ((_ref = this.popup) != null) {
      _ref.close();
    }
    return this.changeStep('bigbutton');
  };

  LeaveGoogleView.prototype.onAuthCodeKeyup = function(event) {
    if (event.keyCode === 13) {
      this.onStep2Done(event);
    }
    if (event.keyCode === 27) {
      return this.onStep2Done(event);
    }
  };

  LeaveGoogleView.prototype.submitLg = function(event) {
    var auth_code, scope;
    event.preventDefault();
    auth_code = this.$("input:text[name=auth_code]").val();
    this.$("input:text[name=auth_code]").val("");
    scope = {
      photos: this.$("input:checkbox[name=photos]").prop("checked"),
      calendars: this.$("input:checkbox[name=calendars]").prop("checked"),
      contacts: this.$("input:checkbox[name=contacts]").prop("checked")
    };
    $.post("lg", {
      auth_code: auth_code,
      scope: scope
    });
    return window.app.router.navigate('status', true);
  };

  return LeaveGoogleView;

})(BaseView);

});

require.register("views/leave_google_log", function(exports, require, module) {
var BaseView, LeaveGoogleLogView,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

BaseView = require('../lib/base_view');

module.exports = LeaveGoogleLogView = (function(_super) {
  __extends(LeaveGoogleLogView, _super);

  function LeaveGoogleLogView() {
    return LeaveGoogleLogView.__super__.constructor.apply(this, arguments);
  }

  LeaveGoogleLogView.prototype.template = require('./templates/leave_google_log');

  LeaveGoogleLogView.prototype.tagName = 'section';

  LeaveGoogleLogView.prototype.id = 'leave-google';

  LeaveGoogleLogView.prototype.model = {
    photos: {
      processing: true,
      numberPhotos: 0,
      numberAlbum: 0,
      error: []
    },
    contacts: {
      processing: true,
      number: 0
    },
    events: {
      processing: true,
      number: 0,
      total: 0
    }
  };

  LeaveGoogleLogView.prototype.initialize = function() {
    window.sio.on("photos.album", (function(_this) {
      return function(data) {
        console.log("photos.album", data.number);
        _this.model.photos.numberAlbum = data.number;
        return _this.render();
      };
    })(this));
    window.sio.on("photos.err", (function(_this) {
      return function(data) {
        console.log("photos.err", data.number);
        console.log(data);
        _this.model.photos.error.push(data.url);
        return _this.render();
      };
    })(this));
    window.sio.on("photos.photo", (function(_this) {
      return function(data) {
        console.log("photos.photo", data.number);
        _this.model.photos.numberPhotos = data.number;
        return _this.render();
      };
    })(this));
    window.sio.on("calendars", (function(_this) {
      return function(data) {
        console.log("calendars", data.number);
        _this.model.events.number = data.number;
        _this.model.events.total = data.total;
        return _this.render();
      };
    })(this));
    window.sio.on("contacts", (function(_this) {
      return function(data) {
        console.log("contacts", data.number);
        _this.model.contacts.number = data.number;
        return _this.render();
      };
    })(this));
    window.sio.on("events.end", (function(_this) {
      return function() {
        console.log("calendars done");
        _this.model.events.processing = false;
        return _this.render();
      };
    })(this));
    window.sio.on("contacts.end", (function(_this) {
      return function() {
        console.log("contacts done");
        _this.model.contacts.processing = false;
        return _this.render();
      };
    })(this));
    window.sio.on("photos.end", (function(_this) {
      return function() {
        console.log("photos done");
        _this.model.photos.processing = false;
        return _this.render();
      };
    })(this));
    return window.sio.on('invalid token', (function(_this) {
      return function() {
        console.log("invalid token");
        _this.model.invalidToken = true;
        _this.render();
        return _this.model.invalidToken = false;
      };
    })(this));
  };

  LeaveGoogleLogView.prototype.afterRender = function() {
    return app.router.navigate('', {
      trigger: false
    });
  };

  LeaveGoogleLogView.prototype.getRenderData = function() {
    return this.model;
  };

  return LeaveGoogleLogView;

})(BaseView);

});

require.register("views/templates/leave_google_form", function(exports, require, module) {
var __templateData = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;

buf.push("<h1>" + (jade.escape(null == (jade_interp = t('leave google title')) ? "" : jade_interp)) + "</h1><div class=\"content\"><section id=\"step-bigbutton\" class=\"step\"><h5>" + (jade.escape(null == (jade_interp = t("leave google step1 title")) ? "" : jade_interp)) + "</h5><a id=\"connect-google\"" + (jade.attr("title", t("leave google connect label"), true, false)) + " class=\"btn\">" + (jade.escape(null == (jade_interp = t("leave google connect label")) ? "" : jade_interp)) + "</a></section><section id=\"step-pastecode\" class=\"step\"><h5>" + (jade.escape(null == (jade_interp = t("leave google step2 title")) ? "" : jade_interp)) + "</h5><form><input id=\"auth_code\" type=\"text\" name=\"auth_code\" placeholder=\"google auth_code\" required=\"required\"/><a id=\"step-pastecode-ok\" class=\"btn\">" + (jade.escape(null == (jade_interp = t('confirm')) ? "" : jade_interp)) + "</a><a id=\"step-pastecode-ko\" class=\"btn\">" + (jade.escape(null == (jade_interp = t('cancel')) ? "" : jade_interp)) + "</a></form></section><section id=\"step-pickscope\" class=\"step\"><h5>" + (jade.escape(null == (jade_interp = t('leave google choice title')) ? "" : jade_interp)) + "</h5><label>" + (jade.escape(null == (jade_interp = t("leave google choice photo")) ? "" : jade_interp)) + "<input type=\"checkbox\" name=\"photos\" value=\"photos\" checked=\"checked\"/></label><label>" + (jade.escape(null == (jade_interp = t("leave google choice calendar")) ? "" : jade_interp)) + "<input type=\"checkbox\" name=\"calendars\" value=\"calendars\" checked=\"checked\"/></label><label>" + (jade.escape(null == (jade_interp = t("leave google choice contact")) ? "" : jade_interp)) + "<input type=\"checkbox\" name=\"contacts\" value=\"contacts\" checked=\"checked\"/></label><a id=\"lg-login\" class=\"btn\">" + (jade.escape(null == (jade_interp = t('leave google')) ? "" : jade_interp)) + "</a></section></div>");;return buf.join("");
};
if (typeof define === 'function' && define.amd) {
  define([], function() {
    return __templateData;
  });
} else if (typeof module === 'object' && module && module.exports) {
  module.exports = __templateData;
} else {
  __templateData;
}
});

;require.register("views/templates/leave_google_log", function(exports, require, module) {
var __templateData = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
var locals_ = (locals || {}),photos = locals_.photos,contacts = locals_.contacts,events = locals_.events,invalidToken = locals_.invalidToken;
if ( photos.processing || contacts.processing || events.processing)
{
buf.push("<h1 class=\"pa2 matop0 biggest darkbg center\">Importation en cours ...</h1>");
}
else
{
buf.push("<h1 class=\"pa2 matop0 biggest darkbg center\">Importation terminée</h1>");
}
buf.push("<div class=\"content\"><p>Connexion à l'API de Google.</p>");
if ( photos.numberPhotos)
{
buf.push("<div>");
if ( photos.processing)
{
buf.push("<p>Importation des photos en cours</p>");
}
else
{
buf.push("<p>Importation des photos terminée</p>");
}
buf.push("<p>" + (jade.escape(null == (jade_interp = photos.numberPhotos + " photos importées dans " + photos.numberAlbum + " album(s)") ? "" : jade_interp)) + "</p>");
// iterate photos.error
;(function(){
  var $$obj = photos.error;
  if ('number' == typeof $$obj.length) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var url = $$obj[$index];

buf.push("<p>" + (jade.escape(null == (jade_interp = "Importation impossible : " + url) ? "" : jade_interp)) + "</p>");
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj) {
      $$l++;      var url = $$obj[$index];

buf.push("<p>" + (jade.escape(null == (jade_interp = "Importation impossible : " + url) ? "" : jade_interp)) + "</p>");
    }

  }
}).call(this);

buf.push("</div>");
}
if ( events.number)
{
buf.push("<div>");
if ( events.processing)
{
buf.push("<p>Importation des calendriers en cours</p>");
}
else
{
buf.push("<p>Importation des calendriers terminée</p>");
}
buf.push("<p>" + (jade.escape(null == (jade_interp = events.number + " evenements importés sur " + events.total) ? "" : jade_interp)) + "</p></div>");
}
if ( contacts.number)
{
buf.push("<div>");
if ( contacts.processing)
{
buf.push("<p>Importation des contacts en cours</p>");
}
else
{
buf.push("<p>Importation des contacts terminée</p>");
}
buf.push("<p>" + (jade.escape(null == (jade_interp = contacts.number + " contacts importés") ? "" : jade_interp)) + "</p></div>");
}
if ( invalidToken)
{
buf.push("<div class=\"error\">" + (jade.escape(null == (jade_interp = t('leave google invalid token')) ? "" : jade_interp)) + "</div>");
}
if (!( photos.processing || contacts.processing || events.processing))
{
buf.push("<a href=\"/\" target=\"_top\" class=\"btn\">" + (jade.escape(null == (jade_interp = t('back to home')) ? "" : jade_interp)) + "</a>");
}
buf.push("</div>");;return buf.join("");
};
if (typeof define === 'function' && define.amd) {
  define([], function() {
    return __templateData;
  });
} else if (typeof module === 'object' && module && module.exports) {
  module.exports = __templateData;
} else {
  __templateData;
}
});

;