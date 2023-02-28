(() => /*  */ {
    if (!window.flutter_inappwebview.callHandler) {
        window.flutter_inappwebview.callHandler = function () {
            var _callHandlerID = setTimeout(function () {
            });
            window.flutter_inappwebview._callHandler(arguments[0], _callHandlerID, JSON.stringify(Array.prototype.slice.call(arguments, 1)));
            return new Promise(function (resolve, reject) {
                window.flutter_inappwebview[_callHandlerID] = resolve;
            });
        };
    }

    function registerFbNativeMethod(methodName) {
        window.fbWeb[methodName] = function () {
            var args = [methodName];
            for (var i = 0; i < arguments.length; i++) {
                args.push(arguments[i]);
            }
            return window.flutter_inappwebview.callHandler.apply(this, args);
        };
    }

    window.fbWeb = {};
    registerFbNativeMethod("oAuth");
    if (window.onFanbookReady) window.onFanbookReady();
})();
