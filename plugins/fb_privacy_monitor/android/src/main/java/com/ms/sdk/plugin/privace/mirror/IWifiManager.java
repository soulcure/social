package com.ms.sdk.plugin.privace.mirror;

import android.os.IBinder;
import android.os.IInterface;

import com.ms.sdk.plugin.privace.reflect.MethodParams;
import com.ms.sdk.plugin.privace.reflect.RefClass;
import com.ms.sdk.plugin.privace.reflect.RefStaticMethod;


public class IWifiManager {
    public static Class<?> TYPE = RefClass.load(IWifiManager.class, "android.net.wifi.IWifiManager");

    public static class Stub {
        public static Class<?> TYPE = RefClass.load(Stub.class, "android.net.wifi.IWifiManager$Stub");
        @MethodParams({IBinder.class})
        public static RefStaticMethod<IInterface> asInterface;
    }
}
