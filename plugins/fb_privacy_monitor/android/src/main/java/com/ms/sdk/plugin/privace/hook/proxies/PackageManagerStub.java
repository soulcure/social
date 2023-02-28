package com.ms.sdk.plugin.privace.hook.proxies;

import android.os.IInterface;

import com.ms.sdk.plugin.privace.hook.base.BinderInvocationStub;
import com.ms.sdk.plugin.privace.hook.base.MethodInvocationProxy;
import com.ms.sdk.plugin.privace.hook.base.MethodInvocationStub;
import com.ms.sdk.plugin.privace.hook.base.ThreadStackProxies;
import com.ms.sdk.plugin.privace.mirror.ActivityThread;

/**
 * created by leevin.li on 2021/4/9
 */
public class PackageManagerStub extends MethodInvocationProxy<MethodInvocationStub<IInterface>> {


    public PackageManagerStub() {
        super(new MethodInvocationStub<>(ActivityThread.sPackageManager.get()));
    }

    @Override
    protected void onBindMethods() {
        super.onBindMethods();
//        addMethodProxy(new ThreadStackProxies("getInstallerPackageName"));
        addMethodProxy(new ThreadStackProxies("getInstalledPackages","获取应用安装列表"));
//        addMethodProxy(new ThreadStackProxies("getInstalledPackagesAsUser"));
//        addMethodProxy(new ThreadStackProxies("getInstalledApplications"));
//        addMethodProxy(new ThreadStackProxies("getInstalledApplicationsAsUser"));
        addMethodProxy(new ThreadStackProxies("queryIntentActivities","查询应用安装列表"));
    }

    @Override
    public void inject() throws Throwable {
        final IInterface hookedPM = getInvocationStub().getProxyInterface();
        ActivityThread.sPackageManager.set(hookedPM);
        BinderInvocationStub pmHookBinder = new BinderInvocationStub(getInvocationStub().getBaseInterface());
        pmHookBinder.copyMethodProxies(getInvocationStub());
        pmHookBinder.replaceService("package");
    }

    @Override
    public boolean isEnvBad() {
        return getInvocationStub().getProxyInterface() != ActivityThread.sPackageManager.get();
    }
}
