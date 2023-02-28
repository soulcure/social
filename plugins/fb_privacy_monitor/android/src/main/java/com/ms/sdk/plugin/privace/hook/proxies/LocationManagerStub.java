package com.ms.sdk.plugin.privace.hook.proxies;

import android.content.Context;

import com.ms.sdk.plugin.privace.hook.base.BinderInvocationProxy;
import com.ms.sdk.plugin.privace.hook.base.ThreadStackProxies;
import com.ms.sdk.plugin.privace.mirror.ILocationManager;

/**
 * created by leevin.li on 2021/4/9
 */
public class LocationManagerStub extends BinderInvocationProxy {

    public LocationManagerStub() {
        super(ILocationManager.Stub.asInterface, Context.LOCATION_SERVICE);
    }

    @Override
    protected void onBindMethods() {
        super.onBindMethods();

        addMethodProxy(new ThreadStackProxies("requestLocationUpdates","获取位置信息"));
        addMethodProxy(new ThreadStackProxies("getLastLocation","获取位置信息"));
        addMethodProxy(new ThreadStackProxies("getLastKnownLocation","获取位置信息"));
    }
}
