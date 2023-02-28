package com.ms.sdk.plugin.privace.hook.base;

import android.app.Instrumentation;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.os.IBinder;

import com.ms.sdk.plugin.privace.reflect.Reflect;

/**
 * created by leevin.li on 2021/4/9
 */
public class InstrumentationDelegate  extends Instrumentation {

    protected Instrumentation base;

    public InstrumentationDelegate(Instrumentation base) {
        this.base = base;
    }

    public ActivityResult execStartActivity(
            Context who, IBinder contextThread, IBinder token, String target,
            Intent intent, int requestCode, Bundle options) {
        ActivityResult result = (ActivityResult) Reflect.on(base).call("execStartActivity", who, contextThread, token, target, intent, requestCode, options).get();
        return result;
    }
}
