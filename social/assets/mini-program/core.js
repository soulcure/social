(() => /*  */ {
  if (!window.flutter_inappwebview || !window.flutter_inappwebview.callHandler) {
    window.flutter_inappwebview = {};
    window.flutter_inappwebview.callHandler = function () {
      var _callHandlerID = setTimeout(function () {});
      window.flutter_inappwebview._callHandler(arguments[0], _callHandlerID, JSON.stringify(Array.prototype.slice.call(arguments, 1)));
      return new Promise(function (resolve, reject) {
        window.flutter_inappwebview[_callHandlerID] = resolve;
      });
    };
  }

  function registerFbNativeMethod(methodName) {
    window.fb[methodName] = function () {
      var args = [methodName];
      for (var i = 0; i < arguments.length; i++) {
        args.push(arguments[i]);
      }
      return window.flutter_inappwebview.callHandler.apply(this, args);
    };
  }

  window.debounce = function(fn) {
      let timeout = null;
      return function() {
        var that = this;
        clearTimeout(timeout);
        timeout = setTimeout(function() {
          fn.call(that, arguments);
        }, 100);
      };
    }

  function disableFullScreen() {
    let element = document.documentElement;
    if (element.requestFullscreen) {
        element.requestFullscreen = function(){};
    } else if (element.webkitRequestFullScreen) {
        element.webkitRequestFullScreen = function(){};
    } else if (element.mozRequestFullScreen) {
        element.mozRequestFullScreen = function(){};
    } else if (element.msRequestFullscreen) {
        element.msRequestFullscreen = function(){};
    }
  }

  disableFullScreen();

  window.fb = window.fb || {};


  registerFbNativeMethod("getSystemInfo");
  registerFbNativeMethod("getUserToken");
  registerFbNativeMethod("setClipboardData");
  registerFbNativeMethod("getClipboardData");
  registerFbNativeMethod("getUserInfo");
  registerFbNativeMethod("uploadFile");
  registerFbNativeMethod("getCurrentGuild");
  registerFbNativeMethod("getCurrentChannel");
  registerFbNativeMethod("oAuth");
  registerFbNativeMethod("closeWindow");
  registerFbNativeMethod("getAppVersion");
  registerFbNativeMethod("showShareDialog");
  registerFbNativeMethod("isFromDmChannel");
  registerFbNativeMethod("getDmChannel");
  registerFbNativeMethod("sendMessage");
  registerFbNativeMethod("saveImage");
  registerFbNativeMethod("showInput");
  registerFbNativeMethod("hideInput");
  registerFbNativeMethod("setOrientation");
//  registerFbNativeMethod("showAtList");
//  registerFbNativeMethod("handleTcDocMessage");
//  registerFbNativeMethod("tcDocAtUser");


//  function onMessage(event){
//    var startIdx = event.data.indexOf("[");
//    var endIdx = event.data.lastIndexOf("]");
//    var str = event.data.substring(startIdx,endIdx+1);
//    var data = JSON.parse(str);
//    if(data.length>=1) {
//      fb.handleTcDocMessage(data);
//    }
//  }
//   window.NativeWebsocket = WebSocket;
//   window.WebSocket = function (url, protocols) {
//        if(window.docSocket) {
//           wwindow.docSocket.removeEventListener("message", onMessage);
//        }
//       var WS = new NativeWebsocket(url, protocols) ;
//       if(url.startsWith('wss://docs.qq.com/websocket/?tag=')) {
//             window.docSocket = WS;
//             window.docSocket.addEventListener('message',onMessage);
//      }
//       return WS;
//   }
        window.addEventListener('openapi_init',function(e) {
            window.flutter_inappwebview.callHandler("openapi_init");
      });
       window.addEventListener('DOMContentLoaded',function(e) {
            console.log('DOMContentLoaded');
            window.flutter_inappwebview.callHandler("onDOMContentLoaded")
       });
})();