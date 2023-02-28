package com.ms.sdk.plugin.privace.mirror;


import com.ms.sdk.plugin.privace.reflect.RefClass;
import com.ms.sdk.plugin.privace.reflect.RefMethod;
import com.ms.sdk.plugin.privace.reflect.RefObject;

public class Singleton {
    public static Class<?> TYPE = RefClass.load(Singleton.class, "android.util.Singleton");
    public static RefMethod<Object> get;
    public static RefObject<Object> mInstance;
}
