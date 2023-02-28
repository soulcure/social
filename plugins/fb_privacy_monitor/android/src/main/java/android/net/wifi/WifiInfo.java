package android.net.wifi;

import com.ms.sdk.plugin.privace.reflect.Reflect;
import com.ms.sdk.plugin.privace.util.StackOutput;
import com.ms.sdk.plugin.privace.util.Util;

/**
 * created by leevin.li on 2021/4/9
 */
public class WifiInfo {


    public WifiInfo(){

    }

    public String getMacAddress() {
        return "getMacAddress";
    }

    public int getIpAddress() {
        return 0;
    }

    public static class HackerWifiInfo extends WifiInfo{

        private Object mOrgin;
        public HackerWifiInfo(Object origin){
            mOrgin = origin;
        }

        public String getMacAddress() {
            StackOutput.devicePrint("获取MAC地址", "getConnectionInfo", Util.getStack(Thread.currentThread().getStackTrace()));
            return Reflect.on(mOrgin).call("getMacAddress").get();
        }

        public int getIpAddress() {
            StackOutput.devicePrint("获取IP地址", "getConnectionInfo", Util.getStack(Thread.currentThread().getStackTrace()));
            return Reflect.on(mOrgin).call("getIpAddress").get();
        }
    }
}
