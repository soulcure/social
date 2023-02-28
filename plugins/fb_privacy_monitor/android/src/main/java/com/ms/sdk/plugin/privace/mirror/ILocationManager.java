package com.ms.sdk.plugin.privace.mirror;

import android.os.IBinder;
import android.os.IInterface;

import com.ms.sdk.plugin.privace.reflect.MethodParams;
import com.ms.sdk.plugin.privace.reflect.RefClass;
import com.ms.sdk.plugin.privace.reflect.RefStaticMethod;


public class ILocationManager {

    public static Class<?> TYPE = RefClass.load(ILocationManager.class, "android.location.ILocationManager");

    public static class Stub {
        public static Class<?> TYPE = RefClass.load(Stub.class, "android.location.ILocationManager$Stub");
        @MethodParams({IBinder.class})
        public static RefStaticMethod<IInterface> asInterface;
    }
}
