package com.ms.sdk.plugin.privace.hook.base;

import android.text.TextUtils;
import android.util.Log;


import com.ms.sdk.plugin.privace.util.MethodParameterUtils;

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;

/**
 * author: leevin.li
 * date:  On 2018/11/22.
 * 动态代理类，主要为了解决对监听事件的拦截然后做Dlog上报，所有被注册的方法都会在{@link HookInvocationHandler}中处理
 */

public class MethodInvocationStub<T> {

    public static final String TAG = "MethodInvocationStub";

    private Map<String, MethodProxy> mInternalMethodProxies = new HashMap<>();
    private T mBase;
    private T mProxy;

    public MethodInvocationStub(T baseInterface) {
        this(baseInterface, (Class[]) null);
    }

    public MethodInvocationStub(T base, Class<?>... proxyInterfaces) {
        mBase = base;
        if (base != null) {
            if (proxyInterfaces == null) {
                proxyInterfaces = MethodParameterUtils.getAllInterface(mBase.getClass());
            }
            mProxy = (T) Proxy.newProxyInstance(base.getClass().getClassLoader(), proxyInterfaces, new HookInvocationHandler());
        } else {
            Log.w(TAG, "Unable to build HookDelegate: %s.");
        }
    }

    public Map<String, MethodProxy> getAllHooks() {
        return mInternalMethodProxies;
    }

    /**
     * Copy all proxies from the input HookDelegate.
     *
     * @param from the HookDelegate we copy from.
     */
    public void copyMethodProxies(MethodInvocationStub from) {
        this.mInternalMethodProxies.putAll(from.getAllHooks());
    }


    /**
     * @return Proxy interface
     */
    public T getProxyInterface() {
        return mProxy;
    }

    /**
     * @return Origin Interface
     */
    public T getBaseInterface() {
        return mBase;
    }

    /**
     * @param methodProxy proxy
     */
    public MethodProxy addMethodProxy(MethodProxy methodProxy) {
        if (methodProxy != null && !TextUtils.isEmpty(methodProxy.getMethodName())) {
            if (mInternalMethodProxies.containsKey(methodProxy.getMethodName())) {
                Log.w(TAG, "The Hook(%s, %s) you added has been in existence." + methodProxy.getMethodName() +
                        methodProxy.getClass().getName());
                return methodProxy;
            }
            mInternalMethodProxies.put(methodProxy.getMethodName(), methodProxy);
        }
        return methodProxy;
    }


    public MethodProxy removeMethodProxy(String hookName) {
        return mInternalMethodProxies.remove(hookName);
    }

    public <H extends MethodProxy> H getMethodProxy(String name) {
        return (H) mInternalMethodProxies.get(name);
    }


    private class HookInvocationHandler implements InvocationHandler {
        @Override
        public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
            MethodProxy methodProxy = getMethodProxy(method.getName());
            boolean useProxy = (methodProxy != null && methodProxy.isEnable());
            String argStr = null;
            Object res = null;
            Throwable exception = null;

            argStr = Arrays.toString(args);
            argStr = argStr.substring(1, argStr.length() - 1);

            try {
                if (useProxy && methodProxy.beforeCall(mBase, method, args)) {
                    res = methodProxy.call(mBase, method, args);
                    res = methodProxy.afterCall(mBase, method, args, res);
                } else {
                    res = method.invoke(mBase, args);
                }
                return res;
            } catch (Throwable t) {
                exception = t;
                if (exception instanceof InvocationTargetException && ((InvocationTargetException) exception).getTargetException() != null) {
                    exception = ((InvocationTargetException) exception).getTargetException();
                }
                // TODO: 2018/11/29 这里暂时不抛出异常，可以拦截掉 methodProxy.call 方法的执行 ，满足目前业务即可，后续有更复杂业务再依情况修改
//                throw exception;
                return exception;
            } finally {
                String retString;
                if (exception != null) {
                    retString = exception.toString();
                } else if (method.getReturnType().equals(void.class)) {
                    retString = "void";
                } else {
                    retString = String.valueOf(res);
                }
                Log.d(TAG, method.getDeclaringClass().getSimpleName() + "." + method.getName() + "(" + argStr + ") => " + retString);
            }
        }
    }

}
