package com.idreamsky.fb_privacy_monitor;

import android.annotation.SuppressLint;
import android.content.Context;
import android.os.Build;
import android.os.Handler;
import android.os.Message;
import android.telephony.TelephonyManager;
import android.util.Log;
import android.widget.Toast;

import androidx.annotation.NonNull;

import com.ms.sdk.plugin.privace.Hacker;

import io.flutter.embedding.engine.plugins.FlutterPlugin;

/** FbPrivacyMonitorPlugin */
public class FbPrivacyMonitorPlugin implements FlutterPlugin {

  private final String TAG = "FbPrivacyMonitorPlugin";

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    Log.d(TAG, "onAttachedToEngine: PrivacyMonitorPlugin is Running");
    //Hacker.start(flutterPluginBinding.getApplicationContext());
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {

  }
}
