package com.idreamsky.buff.live;

import android.app.Activity;
import android.content.Context;
import android.util.Log;

import androidx.annotation.NonNull;

import im.zego.zego_express_engine.internal.ZegoLog;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.Result;

/**
 * MethodChannelPlugin
 * 用于传递方法调用（method invocation），一次性通信，通常用于Dart调用Native的方法：如拍照；
 */
public class MediaProjectionSetPlugin implements FlutterPlugin, MethodChannel.MethodCallHandler {
    public static String CHANNEL = "media_projection_plugin";
    private MethodChannel channel;
    private Context context;
    private Activity activity;
    private Result _result;

    public static String token;
    public static String roomId;
    public static String liveHost;
    public static String pullModeStr;

    public MediaProjectionSetPlugin(Activity activity) {
        this.activity = activity;
    }
//
//    private Handler handler = new Handler() {
//        @Override
//        public void handleMessage(Message msg) {
//            super.handleMessage(msg);
//            String s = (String) msg.obj;
//            _result.success(s);
//        }
//
//    };

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        Log.d(CHANNEL, "onAttachedToEngine");
        channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL);
        context = binding.getApplicationContext();
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        Log.d(CHANNEL, "onDetachedFromEngine");
        channel.setMethodCallHandler(null);
        channel = null;
    }


    @Override
    public void onMethodCall(MethodCall call, Result result) {
        Log.d(CHANNEL, "onMethodCall:::" + call.method);

        _result = result;
        switch (call.method) {//处理来自Dart的方法调用
            case "testSetScreenShare":
                Log.e("q1", "native尝试设置屏幕共享信息");
                break;
            case "setToken":
                token = call.argument("token");
                ZegoLog.log("拿到token::" + token);
                break;
            case "setLiveHost":
                liveHost = call.argument("liveHost");
                ZegoLog.log("拿到liveHost::" + liveHost);
                break;
            case "setRoomId":
                roomId = call.argument("roomId");
                ZegoLog.log("拿到roomId::" + roomId);
                break;
            case "setPullModeStr":
                pullModeStr = call.argument("pullModeStr");
                ZegoLog.log("拿到pullModeStr::" + pullModeStr);
                break;
            default:
                result.notImplemented();

        }
    }
}
