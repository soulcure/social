package com.ms.sdk.plugin.privace;

import android.app.Application;
import android.content.Context;
import android.os.Looper;
import android.util.Log;

/**
 * created by leevin.li on 2021/4/8
 */
public class Hacker {

    public static final String TAG = "Hacker.";

    private static boolean isStartUp;
    public static Context getApplicationContext(){return _applicationContext;}
    private static Context _applicationContext;

    public static void start(Context applicationContext) {
        if (!isStartUp) {
            _applicationContext = applicationContext;
            if (Looper.myLooper() != Looper.getMainLooper()) {
                throw new IllegalStateException("VirtualCore.startup() must called in main thread.");
            }
            try {
                InvocationStubManager invocationStubManager = InvocationStubManager.getInstance();
                invocationStubManager.init();
                invocationStubManager.injectAll();
                SettingsHacker.hack();
            } catch (Throwable e) {
                Log.e(TAG, e.getMessage());
            }
            isStartUp = true;
        }
    }

}
