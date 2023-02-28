package com.ms.sdk.plugin.privace.mirror;

import android.content.pm.ProviderInfo;
import android.os.IBinder;
import android.os.IInterface;

import com.ms.sdk.plugin.privace.reflect.MethodParams;
import com.ms.sdk.plugin.privace.reflect.RefBoolean;
import com.ms.sdk.plugin.privace.reflect.RefClass;
import com.ms.sdk.plugin.privace.reflect.RefMethod;
import com.ms.sdk.plugin.privace.reflect.RefObject;


public class IActivityManager {
    public static Class<?> TYPE = RefClass.load(IActivityManager.class, "android.app.IActivityManager");
    @MethodParams({IBinder.class, boolean.class})
    public static RefMethod<Integer> getTaskForActivity;
    @MethodParams({IBinder.class, int.class})
    public static RefMethod<Void> setRequestedOrientation;
    @MethodParams({IBinder.class, String.class, int.class, int.class})
    public static RefMethod<Void> overridePendingTransition;
    public static RefMethod<Integer> startActivity;
    public static RefMethod<Integer> startActivities;

    public static class ContentProviderHolder {
        public static Class<?> TYPE = RefClass.load(ContentProviderHolder.class, "android.app.IActivityManager$ContentProviderHolder");
        public static RefObject<ProviderInfo> info;
        public static RefObject<IInterface> provider;
        public static RefBoolean noReleaseNeeded;
    }
}
