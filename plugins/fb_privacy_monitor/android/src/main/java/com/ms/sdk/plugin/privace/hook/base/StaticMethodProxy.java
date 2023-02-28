package com.ms.sdk.plugin.privace.hook.base;

/**
 * @author Lody
 */

public class StaticMethodProxy extends MethodProxy {

	private String mName;
    private String mDesc = "";

	public StaticMethodProxy(String name) {
		this.mName = name;
	}

    public StaticMethodProxy(String name,String desc) {
        this.mName = name;
        this.mDesc = desc;
    }

	@Override
	public String getMethodName() {
		return mName;
	}

    public String getDesc() {
        return mDesc;
    }
}
