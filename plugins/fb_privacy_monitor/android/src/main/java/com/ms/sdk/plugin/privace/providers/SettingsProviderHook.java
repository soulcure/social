package com.ms.sdk.plugin.privace.providers;

import android.os.Bundle;
import android.util.Log;

import com.ms.sdk.plugin.privace.hook.base.MethodBox;
import com.ms.sdk.plugin.privace.hook.proxies.InternalProviderHook;
import com.ms.sdk.plugin.privace.util.Util;

import java.lang.reflect.InvocationTargetException;

/**
 * created by leevin.li on 2021/4/19
 */
public class SettingsProviderHook extends InternalProviderHook {

    public static final String TAG = "MS-SDK:Hacker.Settings";

    private static final int METHOD_GET = 0;
    private static final int METHOD_PUT = 1;

    public SettingsProviderHook(Object base) {
        super(base);
    }

    private static int getMethodType(String method) {
        if (method.startsWith("GET_")) {
            return METHOD_GET;
        }
        if (method.startsWith("PUT_")) {
            return METHOD_PUT;
        }
        return -1;
    }

    private static boolean isSecureMethod(String method) {
        return method.endsWith("secure");
    }



    @Override
    public Bundle call(MethodBox methodBox, String method, String arg, Bundle extras) throws InvocationTargetException {
        try {
            int methodType = getMethodType(method);
            if (METHOD_GET == methodType) {
                if ("android_id".equals(arg)) {
                    String stack = Util.getStack(Thread.currentThread().getStackTrace());
                    Log.e(TAG, "android_id " + stack);
                    return methodBox.call();
                }
            }
            if (METHOD_PUT == methodType) {
                if (isSecureMethod(method)) {
                    return null;
                }
            }
            return methodBox.call();
        } catch (InvocationTargetException e) {
            if (e.getCause() instanceof SecurityException) {
                return null;
            }
            throw e;
        }
    }

}
