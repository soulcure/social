package com.ms.sdk.plugin.privace.hook.base;

import android.util.Log;

import com.ms.sdk.plugin.privace.util.StackOutput;
import com.ms.sdk.plugin.privace.util.Util;

import java.lang.reflect.Method;
import java.text.SimpleDateFormat;
import java.util.Date;

/**
 * created by leevin.li on 2021/4/8
 */
public class ThreadStackProxies extends StaticMethodProxy {

    public static final String TAG = "Hacker.ThreadStack";

    public ThreadStackProxies(String name) {
        super(name);
    }

    public ThreadStackProxies(String name, String desc) {
        super(name, desc);
    }

    @Override
    public boolean beforeCall(Object who, Method method, Object... args) {
        StackOutput.devicePrint(getDesc(), getMethodName(), Util.getStack(Thread.currentThread().getStackTrace()));
        return super.beforeCall(who, method, args);
    }
}

