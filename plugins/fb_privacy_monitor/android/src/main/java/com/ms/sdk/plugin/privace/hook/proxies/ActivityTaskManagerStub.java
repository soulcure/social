package com.ms.sdk.plugin.privace.hook.proxies;

import com.ms.sdk.plugin.privace.hook.base.BinderInvocationProxy;
import com.ms.sdk.plugin.privace.hook.base.Inject;

/**
 * created by leevin.li on 2021/4/19
 */
@Inject(AMSMethodProxies.class)
public class ActivityTaskManagerStub extends BinderInvocationProxy {

    public ActivityTaskManagerStub() {
        super(IActivityTaskManager.Stub.TYPE, "activity_task");
    }
}
