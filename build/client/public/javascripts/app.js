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
var ErrorHandler, Router;

ErrorHandler = require('./lib/error_helper');

Router = require('./router');

window.onError = ErrorHandler.onerror;

$(function() {
  var e, locale, locales, pathToSocketIO, polyglot, url;
  try {
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
    console.log(toto.titi);
    return window.sio = io(url, {
      path: pathToSocketIO,
      reconnectionDelayMax: 60000,
      reconectionDelay: 2000,
      reconnectionAttempts: 3
    });
  } catch (_error) {
    e = _error;
    return ErrorHandler.catchError(e);
  }
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

require.register("lib/error_helper", function(exports, require, module) {
exports.onerror = function(msg, url, line, col, error) {
  var data, exception, xhr;
  console.error(msg, url, line, col, error, error != null ? error.stack : void 0);
  exception = (error != null ? error.toString() : void 0) || msg;
  if (exception !== window.lastError) {
    data = {
      data: {
        type: 'error',
        error: {
          msg: msg,
          name: error != null ? error.name : void 0,
          full: exception,
          stack: error != null ? error.stack : void 0
        },
        url: url,
        line: line,
        col: col,
        href: window.location.href
      }
    };
    xhr = new XMLHttpRequest();
    xhr.open('POST', 'log', true);
    xhr.setRequestHeader("Content-Type", "application/json;charset=UTF-8");
    xhr.send(JSON.stringify(data));
    return window.lastError = exception;
  }
};

exports.catchError = function(e) {
  var data, exception, xhr;
  console.error(e, e != null ? e.stack : void 0);
  exception = e.toString();
  if (exception !== window.lastError) {
    data = {
      data: {
        type: 'error',
        error: {
          msg: e.message,
          name: e != null ? e.name : void 0,
          full: exception,
          stack: e != null ? e.stack : void 0
        },
        file: e != null ? e.fileName : void 0,
        line: e != null ? e.lineNumber : void 0,
        col: e != null ? e.columnNumber : void 0,
        href: window.location.href
      }
    };
    xhr = new XMLHttpRequest();
    xhr.open('POST', 'log', true);
    xhr.setRequestHeader("Content-Type", "application/json;charset=UTF-8");
    xhr.send(JSON.stringify(data));
    return window.lastError = exception;
  }
};

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
  "leave google title": "Import From Google",
  "leave google intro": "This tool will import your data from Google inside your Cozy.",
  "leave google step1 title": "Sign in to your Google account and authorize your Cozy to access it. You will get a complex string. Copy it in your clipboard.",
  "leave google email label": "Your Google email",
  "leave google email placeholder": "you@gmail.com",
  "leave google connect label": "Sign in to Google",
  "leave google step2 title": "Then, copy and paste the code from the popup in this field:",
  "leave google choice title": "Choose what you want to do with your data stored on Google servers:",
  "leave google choice photos": "One-time import of Google Photos",
  "leave google choice calendar": "One-time import of Google Calendar",
  "leave google choice contacts": "One-time import of Google Contacts",
  "leave google choice sync gmail": "GMail - Access your email from Cozy",
  "invalid token": "The token is invalid, please restart the process from the beginning.",
  "leave google import data": "import data",
  "import running": "Import running...",
  "import complete": "Import complete!",
  "import album failure": "Import failed for album: ",
  "import photo running": "Photo import running...",
  "import contact running": "Contact import running...",
  "import calendar running": "Calendar import running...",
  "import photo complete": "Photo import complete!",
  "import contact complete": "Contact import complete!",
  "import calendar complete": "Calendar import complete!",
  "import amount photos": " imported photos on ",
  "import amount events": " imported events on ",
  "import amount contacts": " imported contacts on ",
  "gmail account synced": "Your Gmail account is now linked",
  "import success message": "Congratulations, all your Google data were properly imported in your Cozy! Now, you can browse and modify it via the main Cozy applications.",
  "leave google connect another": "Sign in to another account",
  "confirm": "Confirm",
  "google auth_code": "Code provided by Google",
  "back to home": "Back to home"
}
;
});

require.register("locales/fr", function(exports, require, module) {
module.exports = {
  "leave google title": "Importer depuis Google",
  "leave google intro": "Bienvenue dans l’assistant d’import de vos données Google ! Il va vous aider à importer dans votre Cozy toutes vos données stockées chez Google.",
  "leave google step1 title": "Première étape : connectez-vous à votre compte Google et autorisez votre Cozy à y accéder. Google va vous fournir une chaine de caractères complexe. Copiez-la dans votre presse-papier :",
  "leave google email label": "Votre adresse Gmail",
  "leave google email placeholder": "vous@gmail.com",
  "leave google connect label": "Connectez votre compte Google",
  "leave google step2 title": "Puis, copiez-collez le code affiché dans la fenêtre dans ce champ : ",
  "leave google choice title": "Félicitations, votre Cozy est connecté à votre compte Google ! Quelles données souhaitez-vous importer ?",
  "leave google choice photos": "Vos photos",
  "leave google choice calendar": "Vos calendriers",
  "leave google choice contacts": "Vos contacts",
  "leave google choice sync gmail": "Gmail sync",
  "invalid token": "La clé que vous avez saisie est invalide, merci d’essayer de recommencer le processus depuis le début.",
  "leave google import data": "importer les données",
  "import running": "Import en cours…",
  "import complete": "Import terminé !",
  "import album failure": "L’import a échoué pour l’album : ",
  "import photo running": "Import de vos photos en cours…",
  "import contact running": "Import de vos contacts en cours…",
  "import calendar running": "Import de vos calendriers en cours…",
  "import photo complete": "L’import de vos photos est un succès !",
  "import contact complete": "Vos contacts sont à présent importés !",
  "import calendar complete": "L’import de vos calendriers s’est parfaitement déroulé !",
  "import amount photos": " photos importées sur  ",
  "import amount events": " évènements importés sur ",
  "import amount contacts": " contacts importés sur ",
  "gmail account synced": "Votre compte GMail est à présent lié à votre Cozy.",
  "import success message": "Félicitations, toutes vos données ont été importées avec succès de Google dans votre Cozy. Vous pouvez à présent les consulter et les modifier via vos applications Cozy. Accédez aux applications depuis la page d’accueil : ",
  "leave google connect another": "Se connecter à un autre compte",
  "confirm": "Confirmer",
  "google auth_code": "Code d'autorisation Google",
  "back to home": "Retour à l'accueil"
}
;
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

  LeaveGoogleView.prototype.tagName = 'main';

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
      contacts: this.$("input:checkbox[name=contacts]").prop("checked"),
      sync_gmail: this.$("input:checkbox[name=sync_gmail]").prop("checked")
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

  LeaveGoogleLogView.prototype.tagName = 'main';

  LeaveGoogleLogView.prototype.id = 'leave-google';

  LeaveGoogleLogView.prototype.model = {
    photos: {
      processing: true,
      numberPhotos: 0,
      numberAlbum: 0,
      total: 0,
      error: []
    },
    contacts: {
      processing: true,
      number: 0,
      total: 0
    },
    events: {
      processing: true,
      number: 0,
      total: 0
    },
    syncedGmail: false
  };

  LeaveGoogleLogView.prototype.initialize = function() {
    window.sio.on("photos.album", (function(_this) {
      return function(data) {
        _this.model.photos.numberAlbum = data.number;
        return _this.render();
      };
    })(this));
    window.sio.on("photos.err", (function(_this) {
      return function(data) {
        _this.model.photos.error.push(data.url);
        return _this.render();
      };
    })(this));
    window.sio.on("photos.photo", (function(_this) {
      return function(data) {
        _this.model.photos.numberPhotos = data.number;
        _this.model.photos.total = data.total;
        return _this.render();
      };
    })(this));
    window.sio.on("calendars", (function(_this) {
      return function(data) {
        _this.model.events.number = data.number;
        _this.model.events.total = data.total;
        return _this.render();
      };
    })(this));
    window.sio.on("contacts", (function(_this) {
      return function(data) {
        _this.model.contacts.number = data.number;
        _this.model.contacts.total = data.total;
        return _this.render();
      };
    })(this));
    window.sio.on("events.end", (function(_this) {
      return function() {
        _this.model.events.processing = false;
        return _this.render();
      };
    })(this));
    window.sio.on("contacts.end", (function(_this) {
      return function() {
        _this.model.contacts.processing = false;
        return _this.render();
      };
    })(this));
    window.sio.on("photos.end", (function(_this) {
      return function() {
        _this.model.photos.processing = false;
        return _this.render();
      };
    })(this));
    window.sio.on("syncGmail.end", (function(_this) {
      return function() {
        _this.model.syncedGmail = true;
        return _this.render();
      };
    })(this));
    window.sio.on('invalid token', (function(_this) {
      return function() {
        _this.model.invalidToken = true;
        _this.render();
        return _this.model.invalidToken = false;
      };
    })(this));
    return window.sio.on('ok', (function(_this) {
      return function() {
        _this.model.events.processing = false;
        _this.model.contacts.processing = false;
        _this.model.photos.processing = false;
        return _this.render();
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

buf.push("<div class=\"content popup\"><header></header><h1>" + (jade.escape(null == (jade_interp = t('leave google title')) ? "" : jade_interp)) + "</h1><section id=\"step-bigbutton\" class=\"step\"><p class=\"help\">" + (jade.escape(null == (jade_interp = t("leave google intro")) ? "" : jade_interp)) + "</p><div class=\"content-block\"><div class=\"step-number\">1</div><div class=\"text-block\">" + (jade.escape(null == (jade_interp = t("leave google step1 title")) ? "" : jade_interp)) + "</div></div><a id=\"connect-google\"" + (jade.attr("title", t("leave google connect label"), true, false)) + " class=\"btn btn-primary\">" + (jade.escape(null == (jade_interp = t("leave google connect label")) ? "" : jade_interp)) + "</a></section><section id=\"step-pastecode\" class=\"step\"><div class=\"content-block\"><div class=\"step-number\">2</div><div class=\"text-block\">" + (jade.escape(null == (jade_interp = t("leave google step2 title")) ? "" : jade_interp)) + "</div></div><form><label for=\"google-code\" class=\"with-input\"><span>" + (jade.escape(null == (jade_interp = t('google auth_code')) ? "" : jade_interp)) + "</span><input id=\"auth_code\" type=\"text\" name=\"auth_code\" required=\"required\"/></label><a id=\"step-pastecode-ok\" class=\"btn btn-primary\">" + (jade.escape(null == (jade_interp = t('confirm')) ? "" : jade_interp)) + "</a></form></section><section id=\"step-pickscope\" class=\"step google-services-list\"><div class=\"content-block\"><div class=\"step-number\">3</div><div class=\"text-block\">" + (jade.escape(null == (jade_interp = t('leave google choice title')) ? "" : jade_interp)) + "</div></div><label for=\"google-gmail-sync\"><input id=\"google-gmail-sync\" type=\"checkbox\" name=\"sync_gmail\" value=\"sync_gmail\" checked=\"checked\"/><span class=\"google-services-icons gmail\"></span><span>" + (jade.escape(null == (jade_interp = t("leave google choice sync gmail")) ? "" : jade_interp)) + "</span></label><label for=\"google-contacts-import\"><input id=\"google-contacts-import\" type=\"checkbox\" name=\"contacts\" value=\"contacts\" checked=\"checked\"/><span class=\"google-services-icons contacts\"></span><span>" + (jade.escape(null == (jade_interp = t("leave google choice contacts")) ? "" : jade_interp)) + "</span></label><label for=\"google-calendar-import\"><input id=\"google-calendar-import\" type=\"checkbox\" name=\"calendars\" value=\"calendars\" checked=\"checked\"/><span class=\"google-services-icons calendar\"></span><span>" + (jade.escape(null == (jade_interp = t("leave google choice calendar")) ? "" : jade_interp)) + "</span></label><label for=\"google-photos-import\"><input id=\"google-photos-import\" type=\"checkbox\" name=\"photos\" value=\"photos\" checked=\"checked\"/><span class=\"google-services-icons photos\"></span><span>" + (jade.escape(null == (jade_interp = t("leave google choice photos")) ? "" : jade_interp)) + "</span></label><a id=\"lg-login\" class=\"btn btn-primary\">" + (jade.escape(null == (jade_interp = t('leave google import data')) ? "" : jade_interp)) + "</a></section></div>");;return buf.join("");
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
var locals_ = (locals || {}),events = locals_.events,contacts = locals_.contacts,photos = locals_.photos,syncedGmail = locals_.syncedGmail,invalidToken = locals_.invalidToken;
buf.push("<div class=\"content popup\">");
if ( events.processing || contacts.processing || photos.processing)
{
buf.push("<header></header><h1 class=\"pa2 matop0 biggest darkbg center\">" + (jade.escape(null == (jade_interp = t('import running')) ? "" : jade_interp)) + "</h1>");
}
else
{
buf.push("<header></header><h1 class=\"pa2 matop0 biggest darkbg center\">" + (jade.escape(null == (jade_interp = t('import complete')) ? "" : jade_interp)) + "</h1>");
}
buf.push("<div class=\"content processing\">");
if ( syncedGmail)
{
buf.push("<div class=\"block\"><h2><i class=\"fa fa-check\"></i><span>" + (jade.escape(null == (jade_interp = t('gmail account synced')) ? "" : jade_interp)) + "</span></h2></div>");
}
if ( photos.numberPhotos)
{
buf.push("<div class=\"block\">");
if ( photos.processing)
{
buf.push("<h2>" + (jade.escape(null == (jade_interp = t('import photo running')) ? "" : jade_interp)) + "</h2>");
}
else
{
buf.push("<h2><i class=\"fa fa-check\"></i><span>" + (jade.escape(null == (jade_interp = t('import photo complete')) ? "" : jade_interp)) + "</span></h2>");
}
buf.push("<p class=\"help\">" + (jade.escape(null == (jade_interp = photos.numberPhotos + t("import amount photos") + photos.total) ? "" : jade_interp)) + "</p>");
if ( photos.processing)
{
buf.push("<div" + (jade.attr("style", "height: 8px; margin-bottom: 1em; border: 1px solid rgba(0,0,0,.12); background: #33A6FF; border-radius: 20px; width: " + ((photos.numberPhotos/photos.total) * 100) + "%", true, false)) + "></div>");
}
// iterate photos.error
;(function(){
  var $$obj = photos.error;
  if ('number' == typeof $$obj.length) {

    for (var $index = 0, $$l = $$obj.length; $index < $$l; $index++) {
      var url = $$obj[$index];

buf.push("<p class=\"help\">" + (jade.escape(null == (jade_interp = t("import album failure") + url) ? "" : jade_interp)) + "</p>");
    }

  } else {
    var $$l = 0;
    for (var $index in $$obj) {
      $$l++;      var url = $$obj[$index];

buf.push("<p class=\"help\">" + (jade.escape(null == (jade_interp = t("import album failure") + url) ? "" : jade_interp)) + "</p>");
    }

  }
}).call(this);

buf.push("</div>");
}
if ( events.number)
{
buf.push("<div class=\"block\">");
if ( events.processing)
{
buf.push("<h2>" + (jade.escape(null == (jade_interp = t('import calendar running')) ? "" : jade_interp)) + "</h2>");
}
else
{
buf.push("<h2><i class=\"fa fa-check\"></i><span>" + (jade.escape(null == (jade_interp = t('import calendar complete')) ? "" : jade_interp)) + "</span></h2>");
}
buf.push("<p class=\"help\">" + (jade.escape(null == (jade_interp = events.number + t("import amount events") + events.total) ? "" : jade_interp)) + "</p>");
if ( events.processing)
{
buf.push("<div" + (jade.attr("style", "height: 8px; margin-bottom: 1em; border: 1px solid rgba(0,0,0,.12); background: #33A6FF; border-radius: 20px; width: " + ((photos.numberPhotos/photos.total) * 100) + "%", true, false)) + "></div>");
}
buf.push("</div>");
}
if ( contacts.number)
{
buf.push("<div class=\"block\">");
if ( contacts.processing)
{
buf.push("<h2>" + (jade.escape(null == (jade_interp = t('import contact running')) ? "" : jade_interp)) + "</h2>");
}
else
{
buf.push("<h2><i class=\"fa fa-check\"></i><span>" + (jade.escape(null == (jade_interp = t('import contact complete')) ? "" : jade_interp)) + "</span></h2>");
}
buf.push("<p class=\"help\">" + (jade.escape(null == (jade_interp = contacts.number + t("import amount contacts") + contacts.total) ? "" : jade_interp)) + "</p>");
if ( contacts.processing)
{
buf.push("<div" + (jade.attr("style", "height: 8px; margin-bottom: 1em; border: 1px solid rgba(0,0,0,.12); background: #33A6FF; border-radius: 20px; width: " + ((contacts.number/contacts.total) * 100) + "%", true, false)) + "></div>");
}
buf.push("</div>");
}
if ( invalidToken)
{
buf.push("<div class=\"error\">" + (jade.escape(null == (jade_interp = t('invalid token')) ? "" : jade_interp)) + "</div><a id=\"back-button\" href=\"/\" target=\"_top\" class=\"btn btn-secondary\">" + (jade.escape(null == (jade_interp = t('back to home')) ? "" : jade_interp)) + "</a>");
}
if (!( events.processing || contacts.processing || photos.processing))
{
buf.push("<p class=\"help\">" + (jade.escape(null == (jade_interp = t('import success message')) ? "" : jade_interp)) + "</p><a id=\"back-button\" href=\"/\" target=\"_top\" class=\"btn btn-secondary\">" + (jade.escape(null == (jade_interp = t('back to home')) ? "" : jade_interp)) + "</a>");
}
buf.push("</div></div>");;return buf.join("");
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