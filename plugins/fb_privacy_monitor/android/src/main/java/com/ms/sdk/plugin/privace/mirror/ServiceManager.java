package com.ms.sdk.plugin.privace.mirror;

import android.os.IBinder;
import android.os.IInterface;

import com.ms.sdk.plugin.privace.reflect.MethodParams;
import com.ms.sdk.plugin.privace.reflect.RefClass;
import com.ms.sdk.plugin.privace.reflect.RefStaticMethod;
import com.ms.sdk.plugin.privace.reflect.RefStaticObject;

import java.util.Map;


public class ServiceManager {
    public static Class<?> TYPE = RefClass.load(ServiceManager.class, "android.os.ServiceManager");
    @MethodParams({String.class, IBinder.class})
    public static RefStaticMethod<Void> addService;
    public static RefStaticMethod<IBinder> checkService;
    public static RefStaticMethod<IInterface> getIServiceManager;
    public static RefStaticMethod<IBinder> getService;
    public static RefStaticMethod<String[]> listServices;
    public static RefStaticObject<Map<String, IBinder>> sCache;
}
