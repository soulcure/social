package com.glartek.flutter_unity;

import android.annotation.SuppressLint;
import android.content.Context;
import android.util.Log;
import android.view.InputDevice;
import android.view.MotionEvent;
import android.view.View;
import android.widget.FrameLayout;

import com.unity3d.player.UnityPlayer;

public class FlutterTouchView extends View {
    FlutterUnityPlugin _plugin;
    public FlutterTouchView(FlutterUnityPlugin plugin, Context context) {
        super(context);
        _plugin = plugin;
    }

    @SuppressLint("ClickableViewAccessibility")
    @Override
    public boolean onTouchEvent(MotionEvent motionEvent) {
        //Log.d(String.valueOf(this), "onTouchEvent");
        return _plugin.getPlayer().onTouchEvent(motionEvent);
    }
}
