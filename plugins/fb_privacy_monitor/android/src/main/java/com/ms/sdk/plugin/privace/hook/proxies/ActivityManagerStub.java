package com.ms.sdk.plugin.privace.hook.proxies;

import android.content.Context;
import android.os.IInterface;

import com.ms.sdk.plugin.privace.hook.base.BinderInvocationStub;
import com.ms.sdk.plugin.privace.hook.base.Inject;
import com.ms.sdk.plugin.privace.hook.base.MethodInvocationProxy;
import com.ms.sdk.plugin.privace.hook.base.MethodInvocationStub;
import com.ms.sdk.plugin.privace.hook.base.ThreadStackProxies;
import com.ms.sdk.plugin.privace.mirror.ActivityManagerNative;
import com.ms.sdk.plugin.privace.mirror.IActivityManager;
import com.ms.sdk.plugin.privace.mirror.ServiceManager;
import com.ms.sdk.plugin.privace.mirror.Singleton;
import com.ms.sdk.plugin.privace.util.BuildCompat;

/**
 * created by leevin.li on 2021/4/19
 */
@Inject(AMSMethodProxies.class)
public class ActivityManagerStub  extends MethodInvocationProxy<MethodInvocationStub<IInterface>> {

    public ActivityManagerStub() {
        super(new MethodInvocationStub<>(ActivityManagerNative.getDefault.call()));
    }

    @Override
    public void inject() throws Throwable {
        if (BuildCompat.isOreo()) {
            //Android Oreo(8.X)
            Object singleton = ActivityManagerOreo.IActivityManagerSingleton.get();
            Singleton.mInstance.set(singleton, getInvocationStub().getProxyInterface());
        } else {
            if (ActivityManagerNative.gDefault.type() == IActivityManager.TYPE) {
                ActivityManagerNative.gDefault.set(getInvocationStub().getProxyInterface());
            } else if (ActivityManagerNative.gDefault.type() == Singleton.TYPE) {
                Object gDefault = ActivityManagerNative.gDefault.get();
                Singleton.mInstance.set(gDefault, getInvocationStub().getProxyInterface());
            }
        }
        BinderInvocationStub hookAMBinder = new BinderInvocationStub(getInvocationStub().getBaseInterface());
        hookAMBinder.copyMethodProxies(getInvocationStub());
        ServiceManager.sCache.get().put(Context.ACTIVITY_SERVICE, hookAMBinder);
    }


    @Override
    protected void onBindMethods() {
        super.onBindMethods();

        addMethodProxy(new ThreadStackProxies("getRunningAppProcesses","检索应用程序"));
    }

    @Override
    public boolean isEnvBad() {
        return false;
    }




}
