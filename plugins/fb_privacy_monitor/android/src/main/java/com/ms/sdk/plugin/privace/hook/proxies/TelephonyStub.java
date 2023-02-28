package com.ms.sdk.plugin.privace.hook.proxies;

import android.content.Context;

import com.ms.sdk.plugin.privace.hook.base.BinderInvocationProxy;
import com.ms.sdk.plugin.privace.hook.base.ThreadStackProxies;
import com.ms.sdk.plugin.privace.mirror.ITelephony;


/**
 * created by leevin.li on 2021/4/9
 */

public class TelephonyStub extends BinderInvocationProxy {

	public TelephonyStub() {
		super(ITelephony.Stub.asInterface, Context.TELEPHONY_SERVICE);
	}

	@Override
	protected void onBindMethods() {
		super.onBindMethods();
		addMethodProxy(new ThreadStackProxies("getDeviceId","获取IMEI")); //imei
		addMethodProxy(new ThreadStackProxies("getSubscriberId","获取IMSI")); // imsi
		addMethodProxy(new ThreadStackProxies("getAllCellInfo","获取位置信息"));// 基站信息
		addMethodProxy(new ThreadStackProxies("getSimSerialNumber","获取SIM")); // sim卡序列号
		addMethodProxy(new ThreadStackProxies("getCellLocation","获取位置信息")); // 基站信息
		addMethodProxy(new ThreadStackProxies("getNeighboringCellInfo","获取位置信息")); // 基站信息
	}
}
