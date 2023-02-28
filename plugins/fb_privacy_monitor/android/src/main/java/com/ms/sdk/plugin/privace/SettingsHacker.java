package com.ms.sdk.plugin.privace;

import android.provider.Settings;
import android.util.Log;


import com.ms.sdk.plugin.privace.reflect.Reflect;
import com.ms.sdk.plugin.privace.util.Util;

import java.util.HashMap;

/**
 * created by leevin.li on 2021/4/2
 */
public class SettingsHacker {

    public static final String TAG = "MS-SDK:SettingsHacker";

    public static void hack(){
        Object originNameValueCache = Reflect.on(Settings.Secure.class).field("sNameValueCache").get();
        HashMap<String,String> mValues = Reflect.on(originNameValueCache).field("mValues").get();
        HackerMap hackerMap = new HackerMap();
        hackerMap.putAll(mValues);
        Reflect.on(originNameValueCache).set("mValues",hackerMap);
    }

    private static class HackerMap extends HashMap<String,String>{

        @Override
        public String get(Object key) {
            Log.e(TAG,"key:----------->"+ key);
            if ("android_id".equals(key)){
                String stack = Util.getStack(Thread.currentThread().getStackTrace());
                Log.e(TAG,stack);
            }
            return super.get(key);
        }
    }

}
