package com.ms.sdk.plugin.privace.hook.base;

import android.app.Instrumentation;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.os.IBinder;
import android.util.Log;

import com.ms.sdk.plugin.privace.mirror.ActivityThread;
import com.ms.sdk.plugin.privace.util.StackOutput;
import com.ms.sdk.plugin.privace.util.Util;
import com.ms.sdk.plugin.privace.hook.IInjector;

import java.util.Arrays;

/**
 * created by leevin.li on 2021/4/9
 */
public class AppInstrumentation extends InstrumentationDelegate implements IInjector {

    private static final String TAG = "Hacker.Instrumentation";

    private static AppInstrumentation gDefault;


    public static AppInstrumentation getDefault() {
        if (gDefault == null) {
            synchronized (AppInstrumentation.class) {
                if (gDefault == null) {
                    gDefault = create();
                }
            }
        }
        return gDefault;
    }

    private static AppInstrumentation create() {
        Instrumentation instrumentation = ActivityThread.mInstrumentation.get(mainThread());
        if (instrumentation instanceof AppInstrumentation) {
            return (AppInstrumentation) instrumentation;
        }
        return new AppInstrumentation(instrumentation);
    }

    private AppInstrumentation(Instrumentation base) {
        super(base);
    }

    @Override
    public void inject() throws Throwable {
        base = ActivityThread.mInstrumentation.get(mainThread());
        ActivityThread.mInstrumentation.set(mainThread(), this);
    }

    @Override
    public ActivityResult execStartActivity(Context who, IBinder contextThread, IBinder token, String target, Intent intent, int requestCode, Bundle options) {
        String[] permissionsNames = intent.getStringArrayExtra("android.content.pm.extra.REQUEST_PERMISSIONS_NAMES");
        StackOutput.permissionsPrint(requestCode, Arrays.toString(permissionsNames), Util.getStack(Thread.currentThread().getStackTrace()));
        return super.execStartActivity(who, contextThread, token, target, intent, requestCode, options);
    }

    @Override
    public boolean isEnvBad() {
        return !(ActivityThread.mInstrumentation.get(mainThread()) instanceof AppInstrumentation);
    }

    private static Object mainThread() {
        return ActivityThread.currentActivityThread.call();
    }
}
