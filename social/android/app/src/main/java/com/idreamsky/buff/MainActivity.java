package com.idreamsky.buff;

import android.app.Activity;
import android.app.Application.ActivityLifecycleCallbacks;
import android.content.Intent;
import android.media.projection.MediaProjection;
import android.os.Bundle;
import android.os.Handler;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.idreamsky.buff.live.FloatPlugin;
import com.idreamsky.buff.live.MediaProjectionSetPlugin;
import com.idreamsky.buff.live.ScreenCaptureManager;
import com.idreamsky.buff.pay.FbPayUtil;

import org.jetbrains.annotations.NotNull;

import im.zego.media_projection_creator.MediaProjectionCreatorCallback;
import im.zego.media_projection_creator.RequestMediaProjectionPermissionManager;
import im.zego.zego_express_engine.ZegoCustomVideoCaptureManager;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.android.FlutterSurfaceView;
import io.flutter.embedding.android.TransparencyMode;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;


public class MainActivity extends FlutterActivity {
    ChannelUtil channelUtil = new ChannelUtil(this);
    MethodChannel wsMethodChannel;
    FlutterSurfaceView flutterSurfaceView;
    boolean isFirstLoad = true;

    // 除MainActivity以外的其它原生页面
    public Activity nativePage;
    private final ActivityLifecycleCallbacks mActivityLifecycleCallbacks = new ActivityLifecycleCallbacks() {

        @Override
        public void onActivityCreated(@NonNull Activity activity, @Nullable Bundle bundle) {

        }

        @Override
        public void onActivityStarted(@NonNull Activity activity) {

        }

        @Override
        public void onActivityResumed(@NonNull Activity activity) {
            nativePage = (activity instanceof MainActivity) ? null : activity;
        }

        @Override
        public void onActivityPaused(@NonNull Activity activity) {

        }

        @Override
        public void onActivityStopped(@NonNull Activity activity) {

        }

        @Override
        public void onActivitySaveInstanceState(@NonNull Activity activity, @NonNull Bundle bundle) {

        }

        @Override
        public void onActivityDestroyed(@NonNull Activity activity) {

        }
    };

    private MediaProjectionCreatorCallback mediaProjectionCreatorCallback = new MediaProjectionCreatorCallback() {
        @Override
        public void onMediaProjectionCreated(MediaProjection mediaProjection, int errorCode) {
            if (errorCode == RequestMediaProjectionPermissionManager.ERROR_CODE_SUCCEED) {
                Log.i("ZEGO", "Create media projection succeeded!");
                ScreenCaptureManager.getInstance().init(getContext(), mediaProjection);
            } else if (errorCode == RequestMediaProjectionPermissionManager.ERROR_CODE_FAILED_USER_CANCELED) {
                Log.e("ZEGO", "Create media projection failed because can not get permission");
            } else if (errorCode == RequestMediaProjectionPermissionManager.ERROR_CODE_FAILED_SYSTEM_VERSION_TOO_LOW) {
                Log.e("ZEGO", "Create media projection failed because system api level is lower than 21");
            }
        }
    };

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        channelUtil.handleOpenClick();
        channelUtil.initNotificationChannel();
        channelUtil.clearAllNotification();

        RequestMediaProjectionPermissionManager.getInstance().setRequestPermissionCallback(mediaProjectionCreatorCallback);
        ZegoCustomVideoCaptureManager.getInstance().setCustomVideoCaptureHandler(ScreenCaptureManager.getInstance());

        getApplication().registerActivityLifecycleCallbacks(mActivityLifecycleCallbacks);
    }

    @Override
    protected void onDestroy() {
        getApplication().unregisterActivityLifecycleCallbacks(mActivityLifecycleCallbacks);
        super.onDestroy();
    }

    @Override
    protected void onResume() {
        super.onResume();
        try {
            if (isFirstLoad) {
                isFirstLoad = false;
            } else {
                new Handler().postDelayed(new Runnable() {
                    @Override
                    public void run() {
                        channelUtil.reconnectWs(wsMethodChannel);
                    }
                }, 2000); // 延时2秒
                if (flutterSurfaceView != null) flutterSurfaceView.postInvalidate();
            }
        }catch (Exception e) {
            e.printStackTrace();
        }
    }

    @NonNull
    @NotNull
    @Override
    public TransparencyMode getTransparencyMode() {
        return TransparencyMode.transparent;
    }

    @Override
    public void onFlutterSurfaceViewCreated(@NonNull FlutterSurfaceView flutterSurfaceView) {
        super.onFlutterSurfaceViewCreated(flutterSurfaceView);
        try {
            flutterSurfaceView.setWillNotDraw(false);
            this.flutterSurfaceView = flutterSurfaceView;
        }catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "android/back/desktop").setMethodCallHandler(channelUtil);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "buff.com/social").setMethodCallHandler(channelUtil);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "buff.com/jpush").setMethodCallHandler(channelUtil);
        wsMethodChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "buff.com/ws");
        wsMethodChannel.setMethodCallHandler(channelUtil);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "buff.com/fbUtils").setMethodCallHandler(channelUtil);

        flutterEngine.getPlugins().add(new MediaProjectionSetPlugin(this));
        flutterEngine.getPlugins().add(new FloatPlugin(this, flutterEngine));
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        FbPayUtil.onActivityResult(this, requestCode, resultCode, data);
        Log.d("FbPayUtil", "onActivityResult - requestCode:" + requestCode + " resultCode:" + resultCode);
    }
}
