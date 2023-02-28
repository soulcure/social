package com.ms.sdk.plugin.privace.hook.base;

import java.lang.reflect.Method;

/**
 * author: leevin.li
 * date:  On 2018/11/23.
 * 方法封装类
 */

public abstract class MethodProxy {

    private boolean enable = true;

    public MethodProxy() {

    }

    public abstract String getMethodName();

    public boolean beforeCall(Object who, Method method, Object... args) {
        return true;
    }

    public Object call(Object who, Method method, Object... args) throws Throwable {
        return method.invoke(who, args);
    }

    public Object afterCall(Object who, Method method, Object[] args, Object result) throws Throwable {
        return result;
    }

    public boolean isEnable() {
        return enable;
    }

    public void setEnable(boolean enable) {
        this.enable = enable;
    }

    @Override
    public String toString() {
        return "Method : " + getMethodName();
    }
}
