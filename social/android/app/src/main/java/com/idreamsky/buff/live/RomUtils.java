package com.idreamsky.buff.live;

import android.app.AppOpsManager;
import android.content.Context;
import android.database.Cursor;
import android.net.Uri;
import android.os.Build;
import android.os.Process;
import android.provider.Settings;

import org.jetbrains.annotations.NotNull;

import java.lang.reflect.Method;

public class RomUtils {
    public final boolean isXiaoMi() {
        return checkManufacturer("xiaomi");
    }

    public final boolean isOppo() {
        return checkManufacturer("oppo");
    }

    public final boolean isVivo() {
        return checkManufacturer("vivo");
    }

    private boolean checkManufacturer(String manufacturer) {
        return manufacturer.equalsIgnoreCase(Build.MANUFACTURER);
    }

    public final boolean isBackgroundStartAllowed(@NotNull Context context) {
        if (isXiaoMi()) {
            return isXiaomiBgStartPermissionAllowed(context);
        } else if (isVivo()) {
            return isVivoBgStartPermissionAllowed(context);
        } else {
            return isOppo() && Build.VERSION.SDK_INT >= 23 ? Settings.canDrawOverlays(context) : true;
        }
    }

    private boolean isXiaomiBgStartPermissionAllowed(Context context) {
        AppOpsManager ops = (AppOpsManager) context.getSystemService(Context.APP_OPS_SERVICE);

        try {
            int op = 10021;
            Method method = ops.getClass().getMethod("checkOpNoThrow", Integer.TYPE, Integer.TYPE, String.class);
            Object result = method.invoke(ops, Integer.valueOf(op), Process.myUid(), context.getPackageName());
            if (result == null) {
                return false;
            } else {
                return (Integer) result == AppOpsManager.MODE_ALLOWED;
            }
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    private boolean isVivoBgStartPermissionAllowed(Context context) {
        return getVivoBgStartPermissionStatus(context) == 0;
    }

    private final int getVivoBgStartPermissionStatus(Context context) {
        Uri uri = Uri.parse("content://com.vivo.permissionmanager.provider.permission/start_bg_activity");
        String selection = "pkgname = ?";
        String[] selectionArgs = new String[]{context.getPackageName()};
        int state = 1;

        try {
            Cursor cursor = context.getContentResolver().query(uri, null, selection, selectionArgs, null);
            if (cursor != null) {
                if (cursor.moveToFirst()) {
                    state = cursor.getInt(cursor.getColumnIndex("currentstate"));
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        return state;
    }
}
