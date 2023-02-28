package com.ms.sdk.plugin.privace.providers;

import android.os.Build;
import android.os.Bundle;
import android.os.IInterface;

import com.ms.sdk.plugin.privace.mirror.IContentProvider;
import com.ms.sdk.plugin.privace.util.BuildCompat;
import com.ms.sdk.plugin.privace.hook.base.MethodBox;
import com.ms.sdk.plugin.privace.hook.proxies.InternalProviderHook;

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;
import java.util.HashMap;
import java.util.Map;

/**
 * created by leevin.li on 2021/4/19
 */
public class ProviderHook implements InvocationHandler {

    public static final String QUERY_ARG_SQL_SELECTION = "android:query-arg-sql-selection";

    public static final String QUERY_ARG_SQL_SELECTION_ARGS = "android:query-arg-sql-selection-args";

    public static final String QUERY_ARG_SQL_SORT_ORDER = "android:query-arg-sql-sort-order";

    private static final Map<String, HookFetcher> PROVIDER_MAP = new HashMap<>();


    protected final Object mBase;


    static {
        PROVIDER_MAP.put("settings", new HookFetcher() {
            @Override
            public ProviderHook fetch(boolean external, IInterface provider) {
                return new SettingsProviderHook(provider);
            }
        });
    }


    private static HookFetcher fetchHook(String authority) {
        HookFetcher fetcher = PROVIDER_MAP.get(authority);
        if (fetcher == null) {
            fetcher = new HookFetcher() {
                @Override
                public ProviderHook fetch(boolean external, IInterface provider) {
//                    if (external) {
//                        return new ExternalProviderHook(provider);
//                    }
                    return new InternalProviderHook(provider);
                }
            };
        }
        return fetcher;
    }

    private static IInterface createProxy(IInterface provider, ProviderHook hook) {
        if (provider == null || hook == null) {
            return null;
        }
        return (IInterface) Proxy.newProxyInstance(provider.getClass().getClassLoader(), new Class[]{
                IContentProvider.TYPE,
        }, hook);
    }


    public static IInterface createProxy(boolean external, String authority, IInterface provider) {

        if (provider instanceof Proxy && Proxy.getInvocationHandler(provider) instanceof ProviderHook) {
            return provider;
        }
        ProviderHook.HookFetcher fetcher = ProviderHook.fetchHook(authority);
        if (fetcher != null) {
            ProviderHook hook = fetcher.fetch(external, provider);
            IInterface proxyProvider = ProviderHook.createProxy(provider, hook);
            if (proxyProvider != null) {
                provider = proxyProvider;
            }
        }
        return provider;
    }

    public ProviderHook(Object base) {
        this.mBase = base;
    }

    @Override
    public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {

        MethodBox methodBox = new MethodBox(method, mBase, args);
        int start = Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2 ? 1 : 0;

        if(Build.VERSION.SDK_INT >= 30) start = 2;

        String name = method.getName();

        if ("call".equals(name)) {
            if (BuildCompat.isR()) {
                start = 3;
            } else if (BuildCompat.isQ()) {
                start = 2;
            }
            String methodName = (String) args[start];
            String arg = (String) args[start + 1];
            Bundle extras = (Bundle) args[start + 2];
            return call(methodBox, methodName, arg, extras);
        }
        return methodBox.call();
    }



    public Bundle call(MethodBox methodBox, String method, String arg, Bundle extras) throws InvocationTargetException {
        return methodBox.call();
    }

    public interface HookFetcher {
        ProviderHook fetch(boolean external, IInterface provider);
    }

}
