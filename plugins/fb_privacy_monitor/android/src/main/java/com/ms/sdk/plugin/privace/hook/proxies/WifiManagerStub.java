package com.ms.sdk.plugin.privace.hook.proxies;

import android.content.Context;

import com.ms.sdk.plugin.privace.hook.base.BinderInvocationProxy;
import com.ms.sdk.plugin.privace.hook.base.MethodProxy;
import com.ms.sdk.plugin.privace.mirror.IWifiManager;
import com.ms.sdk.plugin.privace.reflect.Reflect;

import java.lang.reflect.Method;

/**
 * created by leevin.li on 2021/4/9
 */
public class WifiManagerStub extends BinderInvocationProxy {


    public WifiManagerStub() {
        super(IWifiManager.Stub.asInterface, Context.WIFI_SERVICE);
    }

    @Override
    protected void onBindMethods() {
        super.onBindMethods();
        addMethodProxy(new GetConnectionInfo());
//        addMethodProxy(new ThreadStackProxies("getConnectionInfo"));
    }

    private final class GetConnectionInfo extends MethodProxy {

        @Override
        public String getMethodName() {
            return "getConnectionInfo";
        }

        @Override
        public Object call(Object who, Method method, Object... args) throws Throwable {
            Object wifiInfo =  method.invoke(who, args);
            return Reflect.on("android.net.wifi.WifiInfo$HackerWifiInfo").create(wifiInfo).get();
        }
    }


}
