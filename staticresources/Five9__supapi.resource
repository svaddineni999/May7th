/*!
 * Five9 iframe communication library
 * version: $f9build-version
 *
 * Copyright (c)2017 Five9, Inc.
 */

(function(factory) {
  if ( typeof define === "function" && define.amd ) {
    define(['underscore'], factory);
  } else if (typeof module === "object" && typeof module.exports === "object") {
    var _ = require('underscore');
    module.exports = factory(_);
  } else {
    window.Five9 = window.Five9 || {};
    window.Five9.RemoteApi = factory(window._);
  }
})(function(_) {

  var FrameStates = {
    FOUND: 'FOUND',
    WAITING_CHECK_RESPONSE: 'WAITING_CHECK_RESPONSE',
    CONNECTED: 'CONNECTED',
    CONNECTION_CLOSED: 'CONNECTION_CLOSED'
  };

  var PostMessageTypes = {
    CHECK_REQUEST: 'CHECK_REQUEST',
    CHECK_RESPONSE: 'CHECK_RESPONSE',
    CONNECTION_REQUEST: 'CONNECTION_REQUEST'
  };

  var Events = function() {
    var _events = {};
    return {
      on: function(name, callback, context) {
        if (!_events[name]) {
          _events[name] = [];
        }
        _events[name].push({callback: callback, context: context, ctx: context || this});
      },
      off: function(name, callback, context) {
        var retain, ev, events, names, i, l, j, k;
        if (!_events) {
          return;
        }
        if (!name && !callback && !context) {
          _events = {};
          return;
        }
        names = name ? [name] : _.keys(_events);
        for (i = 0, l = names.length; i < l; i++) {
          name = names[i];
          events = _events[name];
          if (!events) {
            continue;
          }
          _events[name] = retain = [];
          if (callback || context) {
            for (j = 0, k = events.length; j < k; j++) {
              ev = events[j];
              if ((callback && callback !== ev.callback) || (context && context !== ev.context)) { // NOSONAR
                retain.push(ev);
              }
            }
          }
          if (!retain.length) {
            delete _events[name];
          }
        }
      },
      trigger: function(name) {
        var events = _events[name];
        if (events) {
          var args = [].slice.call(arguments, 1);
          for (var i=0; i<events.length; i++) {
            events[i].callback.apply(events[i].ctx, args);
          }
        }
      }
    };
  };

  var FramesManager = function() {
    var TOP_PATH = 'top';
    var SEPARATOR = '/';
    this._framesInfo = {};
    this.currentWindowPath = null;

    this._findAllFrames = function() {
      var frames = {};
      var iterateAllFrames = function(wind, path) {
        if (wind === window) {
          this.currentWindowPath = path;
        }
        frames[path] = {path:path, window:wind, state:FrameStates.FOUND, port:null, channel:null};
        for (var i = 0; i < wind.length; i++) {
          var nextWindow = wind[i];
          if (!nextWindow) {
            this.frameAccessRestricted = true;
            nextWindow = wind.document.getElementsByTagName("iframe")[i];
          }
          if (nextWindow) {
            iterateAllFrames(nextWindow, path + SEPARATOR + i);
          }
        }
      }.bind(this);
      iterateAllFrames(window.top, TOP_PATH);
      return frames;
    };

    this.getFramesInfo = function(){
      return this._framesInfo;
    };

    this.updateFramesInfo = function() {
      var newFramesInfo = this._findAllFrames();
      _.each(newFramesInfo, function(newFrameInfo) {
        //path can be changed so search by window
        var currFrameInfo = this.getFrameInfoByWindow(newFrameInfo.window);
        if (currFrameInfo) {
          newFrameInfo.state = currFrameInfo.state;
          newFrameInfo.port = currFrameInfo.port;
          newFrameInfo.channel = currFrameInfo.channel;
        }
      }.bind(this));
      this._framesInfo = newFramesInfo;
    };

    this.getFrameInfoByPath = function(path) {
      if (!this._framesInfo[path] && !this.frameAccessRestricted) {
        //new iframes could be loaded since last updateFramesInfo
        this.updateFramesInfo();
      }
      return this._framesInfo[path];
    };

    this.ensureWindowExists = function(wndPath, wnd) {
      var wndInfo = this.getFrameInfoByPath(wndPath);
      if (wndInfo) {
        if (this.frameAccessRestricted || wndInfo.state === FrameStates.FOUND) {
          wndInfo.window = wnd;
        }
      } else {
        this._framesInfo[wndPath] = {path: wndPath, window: wnd, state: FrameStates.FOUND, port: null, channel: null};
      }
    };

    this.getFrameInfoByWindow = function(wnd) {
      return _.findWhere(this._framesInfo, {window: wnd});
    };

    this.getCurrentWindowPath = function() {
      return this.currentWindowPath;
    };

    this.updateFramesInfo();
  };
  FramesManager = new FramesManager();

  var MessageChannel = function(remoteWindowPath, receivedEventBus, onClose) {
    var remoteWindowInfo = FramesManager.getFrameInfoByPath(remoteWindowPath);
    if (remoteWindowInfo) {
      this._remoteWindow = remoteWindowInfo.window;
    }
    this._receivedEventBus = receivedEventBus;

    this.getRemoteWindowInfo = function() {
      if (this._remoteWindow) {
        return FramesManager.getFrameInfoByWindow(this._remoteWindow);
      }
      return null;
    };

    this._isConnectionAlive = function() {
      var wndInfo = this.getRemoteWindowInfo();
      if (wndInfo && wndInfo.port && wndInfo.window) {
        try {
          /* jshint ignore:start */
          wndInfo.window.window;
          /* jshint ignore:end */
          return true;
        }
        catch(ex) {}
      }
      this.close();
      return false;
    };

    this.close = function() {
      var wndInfo = this.getRemoteWindowInfo();
      if (wndInfo) {
        if (wndInfo.port) {
          wndInfo.port.close();
        }
        wndInfo.state = FrameStates.CONNECTION_CLOSED;
        wndInfo.port = null;
        wndInfo.channel = null;
        onClose(this._remoteWindow);
      }
    };

    this.sendMessage = function(eventName, eventData) {
      if (this._isConnectionAlive()) {
        try {
          this.getRemoteWindowInfo().port.postMessage({eventName:eventName, eventData:eventData});
        }
        catch(ex) {
          this.close();
        }
      }
    };

    this._onMessage = function(e) {
      if (e.data && e.data.eventName) {
        this._receivedEventBus.trigger(e.data.eventName, e.data.eventData);
      }
    };

    if (!this._isConnectionAlive()) {
      return null;
    }
    remoteWindowInfo.port.onmessage = this._onMessage.bind(this);
  };

  var ConnectionManager = function(receivedEventBus) {
    var REMOTE_API_NAMESPACE = 'five9:remoteAPI';
    this._receivedEventBus = receivedEventBus;
    this._channels = {};

    this.onChannelClose = function(remoteWindow) {
      //try to restore connection
      this.connect(remoteWindow);
    }.bind(this);

    this.onNewConnection = function(port, remoteWindowPath){
      var remoteWindowInfo = FramesManager.getFrameInfoByPath(remoteWindowPath);
      if (remoteWindowInfo) {
        remoteWindowInfo.port = port;
        var channel = new MessageChannel(remoteWindowPath, this._receivedEventBus, this.onChannelClose);
        if (channel) {
          remoteWindowInfo.channel = channel;
          remoteWindowInfo.state = FrameStates.CONNECTED;
        }
      }
    };

    this.sendMessage = function(eventName, eventData) {
      var framesInfo = FramesManager.getFramesInfo();
      _.each(framesInfo, function(frameInfo) {
        if (frameInfo && frameInfo.channel && frameInfo.window !== window && frameInfo.state === FrameStates.CONNECTED) {
          frameInfo.channel.sendMessage(eventName, eventData);
        }
      }.bind(this));
    };

    this.onCheckResponse = function(senderPath, token){
      var remoteWindowInfo = FramesManager.getFrameInfoByPath(token);
      if (remoteWindowInfo && remoteWindowInfo.state === FrameStates.WAITING_CHECK_RESPONSE) {
        var channel = new window.MessageChannel();
        var connectMessage = {
          namespace: REMOTE_API_NAMESPACE,
          messageType: PostMessageTypes.CONNECTION_REQUEST,
          senderPath: FramesManager.getCurrentWindowPath()
        };
        try {
          remoteWindowInfo.window.postMessage(connectMessage, '*', [channel.port2]);
          this.onNewConnection(channel.port1, remoteWindowInfo.path);
        }
        catch(ex) {}
      }
    };

    this.connect = function(remoteWindow) {
      var frameInfo = FramesManager.getFrameInfoByWindow(remoteWindow);
      if (frameInfo && (frameInfo.state === FrameStates.FOUND || frameInfo.state === FrameStates.CONNECTION_CLOSED)) {
        var checkRequest = {
          namespace: REMOTE_API_NAMESPACE,
          messageType: PostMessageTypes.CHECK_REQUEST,
          senderPath: FramesManager.getCurrentWindowPath(),
          token: frameInfo.path
        };
        try {
          remoteWindow.postMessage(checkRequest, "*");
          frameInfo.state = FrameStates.WAITING_CHECK_RESPONSE;
        }
        catch(ex) {}
      }
    };

    this.connectAll = function() {
      var framesInfo = FramesManager.getFramesInfo();
      _.each(framesInfo, function(frameInfo) {
        if (frameInfo && frameInfo.window !== window) {
          this.connect(frameInfo.window);
        }
      }.bind(this));
    };

    this.onPostMessage = function(e) {
      if (!e || !e.data || e.data.namespace !== REMOTE_API_NAMESPACE) {
        return;
      }
      var senderPath = e.data.senderPath;
      if (e.data.messageType === PostMessageTypes.CHECK_REQUEST) {
        var checkResponse = {
          namespace: REMOTE_API_NAMESPACE,
          messageType: PostMessageTypes.CHECK_RESPONSE,
          senderPath: FramesManager.getCurrentWindowPath(),
          token: e.data.token
        };
        try {
          FramesManager.ensureWindowExists(e.data.senderPath, e.source);
          e.source.postMessage(checkResponse, "*");
        }
        catch(ex) {}
      } else if (e.data.messageType === PostMessageTypes.CHECK_RESPONSE) {
        this.onCheckResponse(senderPath, e.data.token);
      } else if (e.data.messageType === PostMessageTypes.CONNECTION_REQUEST) {
        var port = e.ports[0];
        if (port && senderPath) {
          this.onNewConnection(port, senderPath);
        }
      }
    };
    try {
      window.addEventListener('message', this.onPostMessage.bind(this), false);
    } catch (err) {
      console.warn('Failed to add listener to window.top: ' + err);
    }
    this.connectAll();
  };

  var EventBus = function() {
    var events = new Events();
    var connectionManager = new ConnectionManager(events);
    return {
      on: events.on.bind(events),
      off: events.off.bind(events),
      trigger: connectionManager.sendMessage.bind(connectionManager)
    };
  }();

  var EventsChannel = function(channelName) {
    return {
      on: function(eventName, callback, context) {
        if (eventName) {
          EventBus.on(channelName + ':' + eventName, callback, context);
        }
      },
      off: function(eventName, callback, context) {
        if (eventName) {
          EventBus.off(channelName + ':' + eventName, callback, context);
        }
      },
      trigger: function(eventName, eventData) {
        if (eventName) {
          EventBus.trigger(channelName + ':' + eventName, eventData);
        }
      }
    };
  };

  var MethodsChannel = function(eventsChannel) {
    var _eventsChannel = eventsChannel;
    var _supportedMethods = {};
    var _methodsInProgress = {};
    var METHOD_TIMEOUT = 5000;
    var METHODS_EVENT_NAME = "F9_REMOTE_METHODS_EVENT";
    var EventTypes = {
      CALL: "CALL",
      RESULT: "RESULT"
    };

    var generateGuid = function() {
      var d = Date.now();
      var uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
        var r = (d + Math.random()*16)%16 | 0;
        d = Math.floor(d / 16);
        return (c === 'x' ? r : (r&0x7|0x8)).toString(16);
      });
      return uuid;
    };

    var onMethodSuccess = function(guid, payload) {
      var methodInProgress = _methodsInProgress[guid];
      if (!methodInProgress) {
        return;
      }
      clearTimeout(methodInProgress.expirationTimer);
      if (_.isFunction(methodInProgress.successCb)) {
        methodInProgress.successCb(payload);
      }
      delete _methodsInProgress[guid];
    }.bind(this);

    var onMethodFailure = function(guid, reason) {
      var methodInProgress = _methodsInProgress[guid];
      if (!methodInProgress) {
        return;
      }
      if (_.isFunction(methodInProgress.failCb)) {
        methodInProgress.failCb({reason: reason});
      }
      delete _methodsInProgress[guid];
    }.bind(this);

    var onMethodResult = function(methodResponse) {
      if (_.has(methodResponse, 'successData')) {
        onMethodSuccess(methodResponse.guid, methodResponse.successData);
      } else {
        onMethodFailure(methodResponse.guid, methodResponse.failData);
      }
    }.bind(this);

    var callMethod = function(methodRequest) {
      var func = _supportedMethods[methodRequest.methodName];
      if (!_.isFunction(func)) {
        return;
      }
      func(methodRequest.payload, function(successData) {
        var methodSuccessResponse = {
          guid: methodRequest.guid,
          eventType: EventTypes.RESULT,
          successData: successData
        };
        _eventsChannel.trigger(METHODS_EVENT_NAME, methodSuccessResponse);
      }, function(failData) {
        var methodFailureResponse = {
          guid: methodRequest.guid,
          eventType: EventTypes.RESULT,
          failData: failData
        };
        _eventsChannel.trigger(METHODS_EVENT_NAME, methodFailureResponse);
      });
    }.bind(this);

    _eventsChannel.on(METHODS_EVENT_NAME, function(payload) {
      if (payload && payload.eventType === EventTypes.CALL) {
        callMethod(payload);
      } else if (payload && payload.eventType === EventTypes.RESULT) {
        onMethodResult(payload);
      }
    }.bind(this));

    return {
      call: function (methodName, payload, successCb, failCb) {
        var guid = generateGuid();
        var request = {
          guid: guid,
          eventType: EventTypes.CALL,
          methodName: methodName,
          payload: payload
        };
        var expirationTimer = setTimeout(function() {
          onMethodFailure(guid, 'Timeout');
        }, METHOD_TIMEOUT);

        _methodsInProgress[guid] = {
          successCb: successCb,
          failCb: failCb,
          expirationTimer: expirationTimer
        };
        _eventsChannel.trigger(METHODS_EVENT_NAME, request);
      },
      define: function (methodName, func) {
        //required function signature: func(data, successCb, failCb)
        _supportedMethods[methodName] = func;
      }
    };
  };

  var getChannel;

  var Channel = function(channelName) {
    var eventsChannel = new EventsChannel(channelName);
    var methodsChannel = new MethodsChannel(eventsChannel);
    return {
      Events: eventsChannel,
      Methods: methodsChannel,
      getChannel: function(channelName) {
        return getChannel(channelName);
      }
    };
  };

  var _messageChannels = {};
  getChannel = function(channelName) {
    if (!_messageChannels[channelName]){
      _messageChannels[channelName] = new Channel(channelName);
    }
    return _messageChannels[channelName];
  };

  return getChannel('Five9Remote');
});
