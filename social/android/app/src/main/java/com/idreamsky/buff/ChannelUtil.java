package com.idreamsky.buff;

import android.app.Activity;
import android.app.NotificationManager;
import android.content.pm.ActivityInfo;
import android.content.pm.PackageManager;
import android.os.Build;
import android.text.TextUtils;
import android.view.WindowManager;

import androidx.annotation.NonNull;

import com.idreamsky.buff.pay.FbPayUtil;

import org.json.JSONObject;

import java.lang.ref.WeakReference;
import java.lang.reflect.Method;
import java.util.Map;

import android.net.Uri;

import java.io.InputStream;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

import static android.content.Context.NOTIFICATION_SERVICE;
import static android.content.pm.PackageManager.GET_META_DATA;

public class ChannelUtil implements MethodChannel.MethodCallHandler {
    WeakReference<Activity> activity;

    public ChannelUtil(Activity activity) {
        this.activity = new WeakReference(activity);
    }

    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        switch (call.method) {
            case "getSdkInt":
                result.success(Build.VERSION.SDK_INT);
                break;
            case "backDesktop":
                activity.get().moveTaskToBack(false);
                result.success(true);
                break;
            case "acquireWakeLock":
                acquireWakeLock();
                result.success(null);
                break;
            case "releaseWakeLock":
                releaseWakeLock();
                result.success(null);
                break;
            case "getChannelValue":
                try {
                    ActivityInfo info = activity.get().getPackageManager().getActivityInfo(activity.get().getComponentName(), GET_META_DATA);
                    String value = info.metaData.getString("channelValue");
                    if (value != null) result.success(value);
                    else result.error("default", "default", "default");
                } catch (PackageManager.NameNotFoundException e) {
                    result.error("default", "default", "default");
                    e.printStackTrace();
                }
                break;
            case "startAndroidPay":
                Map<String, String> payParams = call.argument("payParams");
                FbPayUtil.startPay(activity.get(), payParams);
                result.success("");
                break;
            case "getLaunchParam":
                String param;
                if (notificationInfo == null) {
                    param = null;
                } else {
                    param = notificationInfo.toString();
                }
                result.success(param);
                break;
            case "clearAllNotification":
                clearAllNotification();
                result.success(true);
                break;
            case "callOppoNotificationPermission":
                result.success(oppoNotificationPermission());
                break;
            case "getUriData": {
                String path = call.argument("uri");
                Uri uri = Uri.parse(path);

                try {
                    InputStream is = activity.get().getContentResolver().openInputStream(uri);
                    int count = is.available();
                    byte[] bs = new byte[count];
                    is.read(bs);
                    result.success(bs);
                } catch (Exception e) {
                    e.printStackTrace();
                    result.success(new byte[0]);
                }
            }
            break;
            case "closePayPage":
                closePayPage();
                result.success(true);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    /// ??????????????????(???????????????)
    void closePayPage() {
        if (activity.get() == null || (!(activity.get() instanceof MainActivity))) return;
        Activity nativePage = ((MainActivity) activity.get()).nativePage;

        if (nativePage == null) return;
        if (nativePage instanceof com.pay.paytypelibrary.activity.SandWebActivity) {
            if (!nativePage.isFinishing()) {
                nativePage.finish();
            }
        }
    }

    void disconnectWs(MethodChannel channel) {
        channel.invokeMethod("ws_close", null);
    }

    void reconnectWs(MethodChannel channel) {
        channel.invokeMethod("ws_reconnect", null);
    }

    void acquireWakeLock() {
        if (activity.get() != null && activity.get().getWindow() != null) {
            activity.get().getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        }
    }

    void releaseWakeLock() {
        if (activity.get() != null && activity.get().getWindow() != null) {
            activity.get().getWindow().clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        }
    }

    public void clearAllNotification() {
        NotificationManager notiManager = (NotificationManager) activity.get().getSystemService(NOTIFICATION_SERVICE);
        notiManager.cancelAll();
    }

    public void initNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            if (RomUtil.isOppo()) {
                NotificationUtil.createChannel(activity.get(), "fbyy001", "????????????", NotificationManager.IMPORTANCE_MAX, "????????????", "ring2");
                NotificationUtil.createChannel(activity.get(), "fbvm001", "????????????", NotificationManager.IMPORTANCE_MAX, "??????????????????", "ring1");
                NotificationUtil.createChannel(activity.get(), "fbim001", "????????????", NotificationManager.IMPORTANCE_MAX, "IM????????????", "ring2");
            }
            if (RomUtil.isMiui()) {
                NotificationUtil.createChannel(activity.get(), "high_system", "????????????", NotificationManager.IMPORTANCE_MAX, "????????????", "ring2");
            }
            NotificationUtil.delChanel(activity.get(), "notification-channel-ring1");//????????????
            NotificationUtil.delChanel(activity.get(), "notification-channel-ring2");//????????????
        }
    }

    public boolean oppoNotificationPermission() {
        try {
            if (RomUtil.isOppo()) {
                Class oppoApi = Class.forName("com.heytap.msp.push.HeytapPushManager");
                Method method = oppoApi.getDeclaredMethod("requestNotificationPermission"); //????????????
                method.invoke(oppoApi);
                return true;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    private JSONObject notificationInfo = new JSONObject();

    public void handleOpenClick() {
        String data = null;
        //???????????????????????????jpush??????
        if (activity.get().getIntent().getData() != null) {
            data = activity.get().getIntent().getData().toString();
        }
        //??????fcm/oppo/??????/vivo ???????????????jpush??????
        if (TextUtils.isEmpty(data) && activity.get().getIntent().getExtras() != null) {
            data = activity.get().getIntent().getExtras().getString("JMessageExtra");
        }
        if (TextUtils.isEmpty(data)) return;
        try {
            notificationInfo = new JSONObject(data);
        } catch (Exception e) {
            notificationInfo = null;
            e.printStackTrace();
        }
    }
}
