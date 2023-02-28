package com.ms.sdk.plugin.privace.util;

import android.net.wifi.WifiInfo;

/**
 * created by leevin.li on 2021/4/2
 */
public class Util {



    public static String getStack(StackTraceElement[] trace) {
        return getStack(trace, "", -1);
    }


    public static String getStack(StackTraceElement[] trace, String preFixStr, int limit) {
        if ((trace == null) || (trace.length < 3)) {
            return "";
        }
        if (limit < 0) {
            limit = Integer.MAX_VALUE;
        }
        StringBuilder t = new StringBuilder(" \n");
        for (int i = 3; i < trace.length - 3 && i < limit; i++) {
            t.append(preFixStr);
            t.append("at ");
            t.append(trace[i].getClassName());
            t.append(":");
            t.append(trace[i].getMethodName());
            t.append("(" + trace[i].getLineNumber() + ")");
            t.append("\n");
        }
        return t.toString();
    }

}
