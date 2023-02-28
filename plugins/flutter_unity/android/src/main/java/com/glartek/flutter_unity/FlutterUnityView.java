package com.glartek.flutter_unity;

import android.content.Context;
import android.graphics.Color;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;

import androidx.annotation.NonNull;

import org.json.JSONObject;

import io.flutter.Log;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;

public class FlutterUnityView implements PlatformView, MethodChannel.MethodCallHandler {
    private final FlutterUnityPlugin plugin;
    private final int id;
    private final View view;
    private final MethodChannel channel;
    private final boolean _isNativeMode = true;

    FlutterUnityView(FlutterUnityPlugin plugin, Context context, int id) {
        FlutterUnityPlugin.views.add(this);
        this.plugin = plugin;
        this.id = id;
        if(_isNativeMode){
            view = new FlutterTouchView(plugin, context);
            view.setBackgroundColor(Color.TRANSPARENT);
        }else{
            view = new FrameLayout(context);
            //view.setBackgroundColor(Color.BLACK);
        }
        channel = new MethodChannel(plugin.getFlutterPluginBinding().getBinaryMessenger(), "unity_view_" + id);
        channel.setMethodCallHandler(this);
        attach();
    }

    @Override
    public View getView() {
        Log.d(String.valueOf(this), "getView");
        return view;
    }

    @Override
    public void dispose() {
        Log.d(String.valueOf(this), "dispose");
        remove();
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        Log.d(String.valueOf(this), "onMethodCall: " + call.method);
        reattach();
        switch (call.method) {
            case "pause":
                plugin.getPlayer().pause();
                result.success(null);
                break;
            case "resume":
                plugin.getPlayer().resume();
                result.success(null);
                break;
            case "send":
                try {
                    JSONObject jsonObject = new JSONObject();
                    jsonObject.put("id", id);
                    jsonObject.put("data", call.argument("message"));
                    FlutterUnityPlayer.UnitySendMessage((String) call.argument("gameObjectName"), (String) call.argument("methodName"), jsonObject.toString());
                    result.success(null);
                } catch (Exception e) {
                    e.printStackTrace();
                    result.error(null, e.getMessage(), null);
                }
                break;
            default:
                result.notImplemented();
        }
    }

    int getId() {
        return id;
    }

    void onMessage(final String message) {
        Log.d(String.valueOf(this), "onMessage: " + message);
        plugin.getPlayer().post(new Runnable() {
            @Override
            public void run() {
                channel.invokeMethod("onUnityViewMessage", message);
            }
        });
    }

    private void remove() {
        FlutterUnityPlugin.views.remove(this);
        channel.setMethodCallHandler(null);
        if(_isNativeMode) {
            ViewGroup contentView = (ViewGroup) plugin.GetCurrentActivity().findViewById(android.R.id.content);
            ViewGroup mainView = (ViewGroup) (contentView).getChildAt(0);
            if (mainView != null) {
                mainView.removeView(plugin.getPlayer());
            }
            return;
        }

        if (plugin.getPlayer().getParent() == view) {
            if (FlutterUnityPlugin.views.isEmpty()) {
                ((FrameLayout)view).removeView(plugin.getPlayer());
                plugin.getPlayer().pause();
                plugin.resetScreenOrientation();
            } else {
                FlutterUnityPlugin.views.get(FlutterUnityPlugin.views.size() - 1).reattach();
            }
        }
    }

    private void attach() {
        if(_isNativeMode){
            if (plugin.getPlayer().getParent() != null) {
                return;
            }
            ViewGroup contentView = (ViewGroup) plugin.GetCurrentActivity().findViewById(android.R.id.content);
            ViewGroup mainView = (ViewGroup) (contentView).getChildAt(0);
            if (mainView != null) {
                mainView.addView(plugin.getPlayer(),0);
            }
            plugin.getPlayer().windowFocusChanged(plugin.getPlayer().requestFocus());
            plugin.getPlayer().resume();
            return;
        }

        if (plugin.getPlayer().getParent() != null) {
            ((ViewGroup) plugin.getPlayer().getParent()).removeView(plugin.getPlayer());
        }
        ((FrameLayout)view).addView(plugin.getPlayer());
        plugin.getPlayer().windowFocusChanged(plugin.getPlayer().requestFocus());
        plugin.getPlayer().resume();
    }

    private void reattach() {
        if(_isNativeMode)
        {
            //NOTE:Flutter刷新时会调用reattach
            return;
        }

        if (plugin.getPlayer().getParent() != view) {
            attach();
            plugin.getPlayer().post(new Runnable() {
                @Override
                public void run() {
                    channel.invokeMethod("onUnityViewReattached", null);
                }
            });
        }
    }
}
