package com.idreamsky.buff;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.ContentResolver;
import android.content.Context;
import android.net.Uri;
import android.os.Build;
import android.text.TextUtils;
import android.util.Log;

public class NotificationUtil {
    private static final String TAG = "ChannelHelper";
    public static void createChannel(Context context, String channelId, String channelName, int importance, String channelDescription, String sound) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return;
        NotificationManager nm = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
        if (nm == null) return;
        NotificationChannel channel = nm.getNotificationChannel(channelId);
        if (channel == null) {
            channel = new NotificationChannel(channelId, channelName, importance);
            if (!TextUtils.isEmpty(channelDescription)) {
                channel.setDescription(channelDescription);
            }
            Uri coinUri = findUri(context, sound);
            if (coinUri != null) {
                channel.setSound(coinUri, Notification.AUDIO_ATTRIBUTES_DEFAULT);
            }
            nm.createNotificationChannel(channel);
        } else {
            Log.w(TAG, "channel: [" + channelId + "] is already exists");
        }
    }

    public static void delChanel(Context context, String channelId) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return;
        NotificationManager nm = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
        if (nm == null) return;
        NotificationChannel channel = nm.getNotificationChannel(channelId);
        if (channel != null) {
            nm.deleteNotificationChannel(channelId);
        }
    }

    public static Uri findUri(Context context, String sound) {
        try {
            if (TextUtils.isEmpty(sound)) {
                return null;
            }
            int resId = context.getResources().getIdentifier(sound, "raw", context.getPackageName());
            if (resId != 0) {
                Uri soundUri = Uri.parse(ContentResolver.SCHEME_ANDROID_RESOURCE + "://" + context.getPackageName() + "/raw/" + sound);
                Log.d(TAG, "found sound uri:" + soundUri);
                return soundUri;
            } else {
                Log.w(TAG, "not found sound:" + sound);
            }
        } catch (Throwable throwable) {
            throwable.printStackTrace();
        }
        return null;
    }
}
