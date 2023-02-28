package com.ms.sdk.plugin.privace;

import android.os.Build;

import com.ms.sdk.plugin.privace.hook.IInjector;
import com.ms.sdk.plugin.privace.hook.base.AppInstrumentation;
import com.ms.sdk.plugin.privace.util.BuildCompat;
import com.ms.sdk.plugin.privace.hook.proxies.ActivityManagerStub;
import com.ms.sdk.plugin.privace.hook.proxies.ActivityTaskManagerStub;
import com.ms.sdk.plugin.privace.hook.proxies.LocationManagerStub;
import com.ms.sdk.plugin.privace.hook.proxies.PackageManagerStub;
import com.ms.sdk.plugin.privace.hook.proxies.PhoneSubInfoStub;
import com.ms.sdk.plugin.privace.hook.proxies.TelephonyStub;
import com.ms.sdk.plugin.privace.hook.proxies.WifiManagerStub;

import java.util.HashMap;
import java.util.Map;

/**
 * created by leevin.li on 2021/4/8
 */
public class InvocationStubManager {


    private static InvocationStubManager sInstance = new InvocationStubManager();
    private static boolean sInit;

    private Map<Class<?>, IInjector> mInjectors = new HashMap<>(13);

    private InvocationStubManager() {
    }

    public static InvocationStubManager getInstance() {
        return sInstance;
    }

    void injectAll() throws Throwable {
        for (IInjector injector : mInjectors.values()) {
            injector.inject();
        }

    }


    public boolean isInit() {
        return sInit;
    }


    public void init() throws Throwable {
        if (isInit()) {
            throw new IllegalStateException("InvocationStubManager Has been initialized.");
        }
        injectInternal();
        sInit = true;
    }

    private void injectInternal() throws Throwable {
        // imei imsi  mcc mnc loc cid
        addInjector(new TelephonyStub());
        addInjector(new PhoneSubInfoStub());
        // mac address  ip address
        addInjector(new WifiManagerStub());
        // android id
        // 硬件序列号
//        Build.SERIAL;
//        Build.getSerial();
        // 软件列表
        addInjector(new PackageManagerStub());
        // location
        addInjector(new LocationManagerStub());

        addInjector(new ActivityManagerStub());

        addInjector(AppInstrumentation.getDefault());

        if (BuildCompat.isQ()) {
            addInjector(new ActivityTaskManagerStub());
        }

    }


    private void addInjector(IInjector IInjector) {
        mInjectors.put(IInjector.getClass(), IInjector);
    }

    class A extends Build{

    }



}
