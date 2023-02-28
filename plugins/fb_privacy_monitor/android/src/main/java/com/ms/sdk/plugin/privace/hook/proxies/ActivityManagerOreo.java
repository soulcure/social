package com.ms.sdk.plugin.privace.hook.proxies;

import android.os.IInterface;

import com.ms.sdk.plugin.privace.reflect.RefClass;
import com.ms.sdk.plugin.privace.reflect.RefStaticMethod;
import com.ms.sdk.plugin.privace.reflect.RefStaticObject;


/**
 * @author Lody
 */

public class ActivityManagerOreo {

    public static Class<?> TYPE = RefClass.load(ActivityManagerOreo.class, "android.app.ActivityManager");

    public static RefStaticMethod<IInterface> getService;
    public static RefStaticObject<Object> IActivityManagerSingleton;

}
