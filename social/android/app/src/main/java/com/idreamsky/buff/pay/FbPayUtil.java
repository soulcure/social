package com.idreamsky.buff.pay;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.text.TextUtils;
import android.util.Log;

import androidx.annotation.Nullable;

import com.pay.paytypelibrary.OrderInfo;
import com.tencent.mm.opensdk.modelbiz.WXLaunchMiniProgram;
import com.tencent.mm.opensdk.openapi.IWXAPI;
import com.tencent.mm.opensdk.openapi.WXAPIFactory;

import org.json.JSONObject;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.MethodChannel;

import static com.pay.paytypelibrary.PayUtil.PAY_CODE;

/**
 * 支付工具类
 */
public class FbPayUtil {
    public final static String TAG = "FbPayUtil";

    public static final int UNION_CODE = 10;

    /**
     * 发起：杉德支付
     */
    public static void startPay(Activity activity, Map<String, String> payParams) {
        JSONObject orderJson = new JSONObject();
        Log.d(TAG, "startPay --> payParams:" + payParams.size());
        try {

            Log.d(TAG, "notify_url:" + payParams.get("notify_url"));
            Log.d(TAG, "mer_order_no:" + payParams.get("mer_order_no"));
            String ip = AppUtils.getIPAddress(activity);
            if (ip == null) {
                ip = "";
            }
            Log.d(TAG, "1 ip:" + ip);
            ip = ip.replaceAll("\\.", "_");
            Log.d(TAG, "2 ip:" + ip);

            orderJson.put("version", "1.0");
            orderJson.put("sign_type", "MD5");
            orderJson.put("mer_no", "6888802032089"); // 商户编号
            //商户密钥 KEY1
            orderJson.put("mer_key", "37OVu2+TtXY8sVaCtIMWPNsTZG+2jMiEeBaxu6nF3F4qkJ4X1cZCLxvhpiVv0GUq6SQm/vIgank=");
            orderJson.put("mer_order_no", payParams.get("mer_order_no")); // 商户订单号
            orderJson.put("create_time", payParams.get("create_time")); // 订单创建时间
            orderJson.put("expire_time", payParams.get("expire_time")); // 订单失效时间
            orderJson.put("order_amt", payParams.get("order_amt")); // 订单金额
            orderJson.put("notify_url", payParams.get("notify_url")); // 回调地址
            orderJson.put("return_url", ""); // 支付后返回的商户显示页面
            orderJson.put("create_ip", ip); // 客户端的真实IP
            orderJson.put("goods_name", payParams.get("goods_name")); // 商品名称
            orderJson.put("store_id", "000000"); // 门店号
            orderJson.put("product_code", payParams.get("product_code")); // 支付产品编码
            orderJson.put("clear_cycle", "3"); // 清算模式 D1 对应的是 3

            JSONObject payExtraJson = new JSONObject();
//            payExtraJson.put("mer_app_id", "wx6f43fe182ae634e3"); // 微信公众号Appid wx6f43fe182ae634e3
//            payExtraJson.put("openid", "gh_3ab0ece0a93e"); // 微信公众号Openid gh_3ab0ece0a93e
            payExtraJson.put("buyer_id", ""); // 支付宝生活号，空：使用杉德默认的生活号
            payExtraJson.put("wx_app_id", "wx5a6ce7e89c14128d"); // 移动应用Appid
            payExtraJson.put("gh_ori_id", "gh_fdd01b2aee3d"); // 小程序原始id
            payExtraJson.put("path_url", "pages/zf/index?"); // 小程序路径
            payExtraJson.put("miniProgramType", "0"); // 小程序正式版 0，开发版 1，体验版 2

            orderJson.put("pay_extra", payExtraJson.toString());
            orderJson.put("accsplit_flag", "NO"); // 分账标识 NO无分账，YES有分账
            orderJson.put("jump_scheme", "sandcash://scpay"); // 支付宝返回app所配置的域名
            orderJson.put("activity_no", ""); //营销活动编码
            orderJson.put("benefit_amount", ""); //优惠金额
            // MD5KEY
            String signKey = "fSHf2CLk/oIlGo87e2yL/eVRnwTB4rqw5dg4LEBKFbAQmxgE28kb/umTBs9Q3C1bJzSTSfjCDTRMEckuV/F7QXT8/wFwoYVcQvOrIrhlT4AF2f9UwwmmDDd0z/82G9PzFPDp+gBhi9Zixuz+UKFTiw==";

            Map<String, String> signMap = new HashMap<String, String>();
            signMap.put("version", orderJson.getString("version"));
            signMap.put("mer_no", orderJson.getString("mer_no"));
            signMap.put("mer_key", orderJson.getString("mer_key"));
            signMap.put("mer_order_no", orderJson.getString("mer_order_no"));
            signMap.put("create_time", orderJson.getString("create_time"));
            signMap.put("order_amt", orderJson.getString("order_amt"));
            signMap.put("notify_url", orderJson.getString("notify_url"));
            signMap.put("create_ip", orderJson.getString("create_ip"));
            signMap.put("store_id", orderJson.getString("store_id"));
            signMap.put("pay_extra", orderJson.getString("pay_extra"));
            signMap.put("accsplit_flag", orderJson.getString("accsplit_flag"));
            signMap.put("sign_type", orderJson.getString("sign_type"));

            if (!TextUtils.isEmpty(orderJson.optString("activity_no"))) {
                signMap.put("activity_no", orderJson.getString("activity_no"));
            }
            if (!TextUtils.isEmpty(orderJson.optString("benefit_amount"))) {
                signMap.put("benefit_amount", orderJson.getString("benefit_amount"));
            }

            List<Map.Entry<String, String>> list = MD5Utils.sortMap(signMap);
            StringBuilder signData = new StringBuilder();
            for (Map.Entry<String, String> m : list) {
                signData.append(m.getKey());
                signData.append("=");
                signData.append(m.getValue());
                signData.append("&");
            }
            signData.append("key");
            signData.append("=");
            signData.append(signKey);
            Log.d(TAG, signData.toString());

            orderJson.put("sign", MD5Utils.getMD5(signData.toString()).toUpperCase()); // MD5签名结果

            Log.d(TAG, " -- orderJson:" + orderJson.toString());

            com.pay.paytypelibrary.PayUtil.CashierPay(activity, orderJson.toString());
        } catch (Exception e) {
            e.getStackTrace();
        }
    }

    public static void onActivityResult(Activity activity, int requestCode, int resultCode, @Nullable Intent data) {
        Log.d(TAG, "onActivityResult -- activity:" + activity);
        if (data == null) {
            return;
        }
        Bundle extras = data.getExtras();
        Uri uri = data.getData();
        Log.d(TAG, "onActivityResult -- extras:" + extras + " uri：" + uri);

        if (resultCode == Activity.RESULT_OK) {
            switch (requestCode) {
                case PAY_CODE:
                    OrderInfo orderInfo = (OrderInfo) data.getSerializableExtra("orderInfo");
                    if (orderInfo != null) {
                        Log.d(TAG, "onActivityResult -- TradeNo:" + orderInfo.getTradeNo() + " activity：" + activity);
                        if (!TextUtils.isEmpty(orderInfo.getTokenId())) {
                            startWxpay(activity, orderInfo);
                        } else if (!TextUtils.isEmpty(orderInfo.getTradeNo())) {
//                            startUnionpay(activity, orderInfo.getTradeNo());
                        } else if (!TextUtils.isEmpty(orderInfo.getSandTn())) {
//                            startSandPay(MainActivity.this, orderInfo.getSandTn());
                        } else if (!TextUtils.isEmpty(orderInfo.getTradeUrl())) {
//                            startLinkpay(activity, orderInfo.getTradeUrl());
                        }
                    }
                    break;
                case UNION_CODE:
                    Bundle bundle = data.getExtras();
                    if (null == bundle) {
                        return;
                    }

                    String message = "支付异常";
                    /*
                     * 支付控件返回字符串:
                     * success、fail、cancel 分别代表支付成功，支付失败，支付取消
                     */
                    String result = bundle.getString("pay_result");
                    Log.i(TAG, "支付结果： result:" + result);
                    if (result != null) {
                        if (result.equalsIgnoreCase("success")) {
                            message = "支付成功";
                        } else if (result.equalsIgnoreCase("fail")) {
                            message = "支付失败";
                        } else if (result.equalsIgnoreCase("cancel")) {
                            message = "用户取消支付";
                        }
                    }

                    AlertDialog.Builder builder = new AlertDialog.Builder(activity);
                    builder.setMessage(message);
                    builder.setInverseBackgroundForced(true);
                    builder.setNegativeButton("确定", new DialogInterface.OnClickListener() {
                        @Override
                        public void onClick(DialogInterface dialog, int which) {
                            dialog.dismiss();
                        }
                    });
                    builder.create().show();
                    break;
            }
        }
    }

    /**
     * 微信小程序
     */
    public static void startWxpay(Context context, OrderInfo orderInfo) {
        String appId = orderInfo.getWxAppId(); // 填应用AppId
        IWXAPI api = WXAPIFactory.createWXAPI(context, appId);
        api.registerApp(appId);
        WXLaunchMiniProgram.Req req = new WXLaunchMiniProgram.Req();
        req.userName = orderInfo.getGhOriId(); // 填小程序原始id
        //拉起小程序页面的可带参路径，不填默认拉起小程序首页，对于小游戏，可以只传入 query 部分，来实现传参效果，如：传入 "?foo=bar"。
        req.path = orderInfo.getPathUrl() + "token_id=" + orderInfo.getTokenId();
        req.miniprogramType = Integer.parseInt(orderInfo.getMiniProgramType());// 可选打开 开发版，体验版和正式版
        api.sendReq(req);
    }

}
