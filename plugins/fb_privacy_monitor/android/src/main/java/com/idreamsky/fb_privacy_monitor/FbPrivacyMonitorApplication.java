package com.idreamsky.fb_privacy_monitor;

import android.content.Context;
import android.util.Log;

import com.ms.sdk.plugin.privace.Hacker;

import io.flutter.app.FlutterApplication;

public class FbPrivacyMonitorApplication extends FlutterApplication {
    @Override
    protected void attachBaseContext(Context base) {
        super.attachBaseContext(base);

        Log.d("FbPMApplication", "attachBaseContext: ");
        Hacker.start(this);
    }
}
