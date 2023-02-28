package com.ms.sdk.plugin.privace.hook.proxies;

import com.ms.sdk.plugin.privace.hook.base.BinderInvocationProxy;
import com.ms.sdk.plugin.privace.hook.base.ThreadStackProxies;
import com.ms.sdk.plugin.privace.mirror.IPhoneSubInfo;

/**
 * created by leevin.li on 2021/4/9
 */
public class PhoneSubInfoStub extends BinderInvocationProxy {

    public PhoneSubInfoStub() {
        super(IPhoneSubInfo.Stub.asInterface, "iphonesubinfo");
    }

    @Override
    protected void onBindMethods() {
        super.onBindMethods();

//          NAI的全称是Network Access Identifier，为接入点网络  比如 移动 联通 等等
//        addMethodProxy(new ThreadStackProxies("getNaiForSubscriber"));

        addMethodProxy(new ThreadStackProxies("getImeiForSubscriber","获取IMEI"));
//        addMethodProxy(new ThreadStackProxies("getDeviceSvn"));
//        addMethodProxy(new ThreadStackProxies("getDeviceSvnUsingSubId"));

        // imsi
        addMethodProxy(new ThreadStackProxies("getSubscriberId","获取IMSI"));
        addMethodProxy(new ThreadStackProxies("getSubscriberIdForSubscriber","获取IMSI"));
        // sim卡序列号
        addMethodProxy(new ThreadStackProxies("getSimSerialNumber","获取SIM"));
        // 获取手机号码的字母识别号
//        addMethodProxy(new ThreadStackProxies("getGroupIdLevel1"));
//        addMethodProxy(new ThreadStackProxies("getGroupIdLevel1ForSubscriber"));
        //用于取手机号码的
        addMethodProxy(new ThreadStackProxies("getLine1Number","获取手机号码"));
        addMethodProxy(new ThreadStackProxies("getLine1NumberForSubscriber","获取手机号码"));
//        addMethodProxy(new ThreadStackProxies("getLine1AlphaTag"));
//        addMethodProxy(new ThreadStackProxies("getLine1AlphaTagForSubscriber"));
//        addMethodProxy(new ThreadStackProxies("getMsisdn"));
//        addMethodProxy(new ThreadStackProxies("getMsisdnForSubscriber"));
        // 语音相关权限
//        addMethodProxy(new ThreadStackProxies("getVoiceMailNumber"));
//        addMethodProxy(new ThreadStackProxies("getVoiceMailNumberForSubscriber"));
//        addMethodProxy(new ThreadStackProxies("getVoiceMailAlphaTag"));
//        addMethodProxy(new ThreadStackProxies("getVoiceMailAlphaTagForSubscriber"));
    }
}
