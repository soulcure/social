package com.ms.sdk.plugin.privace.hook.proxies;

import android.content.pm.ProviderInfo;
import android.os.IInterface;

import com.ms.sdk.plugin.privace.hook.base.MethodProxy;
import com.ms.sdk.plugin.privace.mirror.ContentProviderHolderOreo;
import com.ms.sdk.plugin.privace.mirror.IActivityManager;
import com.ms.sdk.plugin.privace.providers.ProviderHook;
import com.ms.sdk.plugin.privace.util.BuildCompat;

import java.lang.reflect.Method;

/**
 * created by leevin.li on 2021/4/19
 */
public class AMSMethodProxies {


    static class GetContentProviderExternal extends GetContentProvider {

        @Override
        public String getMethodName() {
            return "getContentProviderExternal";
        }

        @Override
        public int getProviderNameIndex() {
            return 0;
        }

        @Override
        public int getPackageIndex() {
            return -1;
        }

        @Override
        public boolean isEnable() {
            return true;
        }
    }

    static class GetContentProvider extends MethodProxy {

        @Override
        public String getMethodName() {
            return "getContentProvider";
        }


        @Override
        public Object call(Object who, Method method, Object... args) throws Throwable {
            Object holder = method.invoke(who, args);
            ProviderInfo info ;
            if (holder != null) {
                if (BuildCompat.isOreo()) {
                    IInterface provider = ContentProviderHolderOreo.provider.get(holder);
                    info = ContentProviderHolderOreo.info.get(holder);
                    if (provider != null) {
                        provider = ProviderHook.createProxy(true, info.authority, provider);
                    }
                    ContentProviderHolderOreo.provider.set(holder, provider);
                } else {
                    IInterface provider = IActivityManager.ContentProviderHolder.provider.get(holder);
                    info = IActivityManager.ContentProviderHolder.info.get(holder);
                    if (provider != null) {
                        provider = ProviderHook.createProxy(true, info.authority, provider);
                    }
                    IActivityManager.ContentProviderHolder.provider.set(holder, provider);
                }
                return holder;
            }
            return null;
        }

        public int getProviderNameIndex() {
            if (BuildCompat.isQ()) {
                return 2;
            }
            return 1;
        }

        public int getPackageIndex() {
            if (BuildCompat.isQ()) {
                return 1;
            }
            return -1;
        }

        @Override
        public boolean isEnable() {
            return true;
        }
    }
}
