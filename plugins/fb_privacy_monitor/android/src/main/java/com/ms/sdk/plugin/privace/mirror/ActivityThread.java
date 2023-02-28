package com.ms.sdk.plugin.privace.mirror;

import android.app.Instrumentation;
import android.os.IInterface;

import com.ms.sdk.plugin.privace.reflect.RefClass;
import com.ms.sdk.plugin.privace.reflect.RefObject;
import com.ms.sdk.plugin.privace.reflect.RefStaticMethod;
import com.ms.sdk.plugin.privace.reflect.RefStaticObject;

/**
 * created by leevin.li on 2021/4/9
 */
public class ActivityThread {

    public static Class<?> TYPE = RefClass.load(ActivityThread.class, "android.app.ActivityThread");
    public static RefStaticMethod currentActivityThread;
    public static RefStaticObject<IInterface> sPackageManager;
    public static RefObject<Instrumentation> mInstrumentation;

}
