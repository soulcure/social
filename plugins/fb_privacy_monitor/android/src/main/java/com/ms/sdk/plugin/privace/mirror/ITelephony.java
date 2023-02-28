package com.ms.sdk.plugin.privace.mirror;

import android.os.IBinder;
import android.os.IInterface;

import com.ms.sdk.plugin.privace.reflect.MethodParams;
import com.ms.sdk.plugin.privace.reflect.RefClass;
import com.ms.sdk.plugin.privace.reflect.RefStaticMethod;


public class ITelephony {
    public static Class<?> TYPE = RefClass.load(ITelephony.class, "com.android.internal.telephony.ITelephony");

    public static class Stub {
        public static Class<?> TYPE = RefClass.load(Stub.class, "com.android.internal.telephony.ITelephony$Stub");
        @MethodParams({IBinder.class})
        public static RefStaticMethod<IInterface> asInterface;
    }
}
