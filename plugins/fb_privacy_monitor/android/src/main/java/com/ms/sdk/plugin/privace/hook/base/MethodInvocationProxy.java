package com.ms.sdk.plugin.privace.hook.base;

import com.ms.sdk.plugin.privace.hook.IInjector;

import java.lang.reflect.Constructor;
import java.lang.reflect.Modifier;

/**
 * author: leevin.li
 * date:  On 2018/11/27.
 * 继承自 {@link MethodInvocationStub} 进一步封装了对注解处理的相关内容，并且把需要hook的方法统一封装为 {@link MethodProxy}对象
 */

public abstract  class MethodInvocationProxy<T extends MethodInvocationStub>implements IInjector {

    protected T mInvocationStub;

    public MethodInvocationProxy(T invocationStub) {
        this.mInvocationStub = invocationStub;
        // 把注解里面的 MethodProxy 添加进去
        onBindMethods();
        afterHookApply(invocationStub);
    }

    protected void onBindMethods() {
        if (mInvocationStub == null) {
            return;
        }
        Class<? extends MethodInvocationProxy> clazz = getClass();
        Inject inject = clazz.getAnnotation(Inject.class);
        if (inject != null) {
            Class<?> proxiesClass = inject.value();
            Class<?>[] innerClasses = proxiesClass.getDeclaredClasses();
            for (Class<?> innerClass : innerClasses) {
                if (!Modifier.isAbstract(innerClass.getModifiers())
                        && MethodProxy.class.isAssignableFrom(innerClass)) {
                    addMethodProxy(innerClass);
                }
            }
        }
    }

    private void addMethodProxy(Class<?> hookType) {
        try {
            Constructor<?> constructor = hookType.getDeclaredConstructors()[0];
            if (!constructor.isAccessible()) {
                constructor.setAccessible(true);
            }
            MethodProxy methodProxy;
            if (constructor.getParameterTypes().length == 0) {
                methodProxy = (MethodProxy) constructor.newInstance();
            } else {
                methodProxy = (MethodProxy) constructor.newInstance(this);
            }
            mInvocationStub.addMethodProxy(methodProxy);
        } catch (Throwable e) {
            throw new RuntimeException("Unable to instance Hook : " + hookType + " : " + e.getMessage());
        }
    }

    public MethodProxy addMethodProxy(MethodProxy methodProxy) {
        return mInvocationStub.addMethodProxy(methodProxy);
    }


    protected void afterHookApply(T delegate) {
    }



    public T getInvocationStub() {
        return mInvocationStub;
    }

    @Override
    public abstract void inject() throws Throwable;


}
