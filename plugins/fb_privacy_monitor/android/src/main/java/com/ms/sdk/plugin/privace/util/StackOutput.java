package com.ms.sdk.plugin.privace.util;

import android.util.Log;

import com.ms.sdk.plugin.privace.Hacker;

import java.io.BufferedWriter;
import java.io.OutputStreamWriter;
import java.net.HttpURLConnection;
import java.net.URL;
import java.text.SimpleDateFormat;
import java.util.Date;

public class StackOutput {

    private static final String TAG = "MS-SDK:PRIVACE";

    public static void devicePrint(String des, String method, String stack) {
        StringBuffer sb = new StringBuffer();
        SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd HH-mm-ss");
        sb.append(" \n行为触发时间:" + dateFormat.format(new Date().getTime()));
        sb.append("\n行为名称:设备信息->" + des);
        sb.append("\n方法名:" + method);
        sb.append("\n函数调用栈:" + stack);
        print("device", sb.toString());
    }

    public static void permissionsPrint(int requestCode, String permissionsNames, String stack) {
        StringBuffer sb = new StringBuffer();
        SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd HH-mm-ss");
        sb.append(" \n行为触发时间:" + dateFormat.format(new Date().getTime()));
        sb.append("\n行为名称:权限申请->requestCode:" + requestCode +";permissionsNames:"+permissionsNames);
        sb.append("\n函数调用栈:" + stack);
        print("permissions", sb.toString());
    }

    public static void print(final String url, final String content) {
        Log.i(TAG + ":" + url, content);
        new Thread(new Runnable() {
            @Override
            public void run() {
                try {
                    URL urlHttp = new URL("http://" + Hacker.getApplicationContext().getPackageName() + "/" + url);
                    HttpURLConnection httpURLConnection = (HttpURLConnection) urlHttp.openConnection();
                    httpURLConnection.setRequestMethod("POST");

                    BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(httpURLConnection.getOutputStream(), "UTF-8"));
                    writer.write(content);
                    writer.close();

                    httpURLConnection.getResponseCode();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        }).start();
    }

}
