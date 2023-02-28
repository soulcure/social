package com.idreamsky.buff.live;

import static android.content.Context.ACTIVITY_SERVICE;
import static com.idreamsky.buff.live.LiveStatus.*;

import android.annotation.SuppressLint;
import android.annotation.TargetApi;
import android.app.Activity;
import android.app.ActivityManager;
import android.app.AlertDialog;
import android.app.AppOpsManager;
import android.content.ComponentName;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.graphics.Color;
import android.graphics.Outline;
import android.net.Uri;
import android.os.Binder;
import android.os.Build;
import android.provider.Settings;
import android.text.TextUtils;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.TextureView;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewOutlineProvider;
import android.view.WindowManager;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;

import com.idreamsky.buff.R;
import com.idreamsky.buff.MainActivity;
import com.lzf.easyfloat.EasyFloat;
import com.lzf.easyfloat.enums.ShowPattern;
import com.lzf.easyfloat.enums.SidePattern;
import com.lzf.easyfloat.interfaces.OnFloatCallbacks;
import com.lzf.easyfloat.permission.PermissionUtils;

import org.jetbrains.annotations.NotNull;

import java.util.List;
import java.util.Timer;
import java.util.TimerTask;
import java.util.concurrent.TimeUnit;

import im.zego.zegoexpress.ZegoExpressEngine;
import im.zego.zegoexpress.constants.ZegoStreamResourceMode;
import im.zego.zegoexpress.constants.ZegoViewMode;
import im.zego.zegoexpress.entity.ZegoCanvas;
import im.zego.zegoexpress.entity.ZegoPlayerConfig;
import im.zego.zegoexpress.entity.ZegoVideoConfig;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.Result;
import io.reactivex.Observable;
import io.reactivex.disposables.Disposable;


/**
 * MethodChannelPlugin
 * 用于传递方法调用（method invocation），一次性通信，通常用于Dart调用Native的方法：如拍照；
 */
public class FloatPlugin implements FlutterPlugin, MethodChannel.MethodCallHandler {
    public static String CHANNEL = "float_plugin";
    private MethodChannel channel;
    private Context context;
    private Activity activity;
    private Result _result;
    private int status;
    private View floatView;
    private ImageView bgBlack;
    private TextView stateText;
    private TextureView previewFloat;
    /// 加载中loading
    /// 【2021 11.29】出现了拉流失败问题，暂时注释
    private ProgressBar progressBar1;
    private boolean isAnchor = false;
    private ZegoCanvas previewCanvasFloat;
    private String roomId;
    private int viewMode = 1;
    private boolean isScreenSharing;
    private boolean isObs;
    private boolean isShowClose;
    private boolean isNotHandleLive = false;
    /// loading计时器
    private Timer progressTimer;

    private static final int PERIOD = 600;
    private static final int DELAY = 50;
    private Timer mCheckScreenSizeTimer;

    private volatile int mCaptureWidth;
    private volatile int mCaptureHeight;
    private String screenDirection;


    private Timer clickTimer;
    private AlertDialog alertDialog;

    /// 预览悬浮窗


    private static final String TAG = "FlutterFloatWindowPlugin";

    public static final String STREAM = "com.float.click/stream";

    private EventChannel.EventSink clickStream;

    public FloatPlugin(Activity activity, FlutterEngine flutterEngine) {
        this.activity = activity;
        new EventChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), STREAM).setStreamHandler(
                new EventChannel.StreamHandler() {
                    @Override
                    public void onListen(Object args, EventChannel.EventSink events) {
                        clickStream = events;
                    }

                    @Override
                    public void onCancel(Object args) {
                        clickStream = null;
                    }
                }
        );
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        Log.d(CHANNEL, "onAttachedToEngine");
        channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL);
        context = binding.getApplicationContext();
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        Log.d(CHANNEL, "onDetachedFromEngine");
        channel.setMethodCallHandler(null);
        channel = null;
    }

    private static boolean isAppRunningForeground(Context context) {
        ActivityManager activityManager = (ActivityManager) context.getSystemService(ACTIVITY_SERVICE);

        assert activityManager != null;
        List<ActivityManager.RunningAppProcessInfo> runningAppProcessList = activityManager.getRunningAppProcesses();

        for (ActivityManager.RunningAppProcessInfo runningAppProcessInfo : runningAppProcessList) {
            if (runningAppProcessInfo.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND
                    && runningAppProcessInfo.processName.equals(context.getApplicationInfo().processName)) {
                return true;
            }
        }

        return false;
    }

    @SuppressLint("LongLogTag")
    private void handleState(int state) {
        LiveStatus liveStatus = values()[state];
        String _liveStatus;
        switch (liveStatus) {
            case anchorClosesLive: //主播关闭直播
                _liveStatus = "直播结束";
                break;
            case anchorViolation: //主播违规关闭直播
                if (isAnchor) {
                    _liveStatus = "直播\n违规关闭";
                } else {
                    _liveStatus = "直播结束";
                }
                break;
            case anchorLeave: //主播离开
                _liveStatus = "主播\n暂时离开";
                break;
            //                【APP】观众弱网看直播小窗口模式下不应该提示网络断开，没有画面[2021 11.14]
//            case networkError: //网络问题，无法开启直播 //网络连接不稳定 //网络不稳定 //网络错误
//                _liveStatus = "网络断开";
//            break;
            case playStreamFailed: //拉流失败
                _liveStatus = "拉流失败";
//                _liveStatus = "网络断开";
                break;
            case abnormalLogin: //账号异地登录
                _liveStatus = "账号\n异地登录";
                break;
            case pushStreamFailed: //推流失败
                _liveStatus = "直播失败";
                break;
            case kickOutServer:
                if (isAnchor) {
                    _liveStatus = "被踢出\n服务器";
                } else {
                    _liveStatus = "直播结束";
                }
                break;
            default:
                _liveStatus = "";
                break;
        }

        if (!_liveStatus.equals("") && _liveStatus != null) {
            if (stateText != null) {
                stateText.setText(_liveStatus);
            }
            if (bgBlack != null) {
                bgBlack.setVisibility(View.VISIBLE);
            }
        } else {
            if (stateText != null) {
                stateText.setText("");
            }
            if (bgBlack != null) {
                bgBlack.setVisibility(View.GONE);
            }
            Log.e(TAG, "状态正常，播放悬浮窗");
            ZegoExpressEngine engine = ZegoExpressEngine.getEngine();
            if (engine != null) {
                if (isAnchor && !isObs) {
                    engine.startPreview(previewCanvasFloat);
                } else {
                    engine.startPlayingStream(roomId, previewCanvasFloat, getPullConfig());
                }
            }
        }

    }

    /**
     * 是否异常直播状态，比如主播离开等
     */
    private boolean isErrorStatus(int status) {
        LiveStatus _liveStatus = values()[status];
        if (_liveStatus == anchorLeave) {
            return true;
        } else if (_liveStatus == networkError) {
            return true;
        } else if (_liveStatus == pushStreamFailed) {
            return true;
        } else if (_liveStatus == playStreamFailed) {
            return true;
        } else {
            return false;
        }
    }

    @SuppressLint("LongLogTag")
    @Override
    public void onMethodCall(MethodCall call, @NotNull Result result) {
        Log.d(CHANNEL, "onMethodCall:::" + call.method);

        // 【2021 12.02】解决直播间内有多个首帧绘制回调与尺寸变更回调
        String useEngineMethod = "changeViewMode,liveStatusChange,screenDirectionChange";
        if (!EasyFloat.isShow() && useEngineMethod.contains(call.method)) {
            Log.d(CHANNEL, "未显示小窗不允许使用:" + call.method + "方法");
            return;
        }
        _result = result;
        switch (call.method) {//处理来自Dart的方法调用
            case "requestPermission":
                if (activity != null) {
                    DeviceUtil.requestFloatPermission(activity);
                } else {
                    DeviceUtil.requestFloatPermission((Activity) context);
                }
                result.success("");
                break;
            case "isRequestFloatPermission":
                if (activity != null) {
                    result.success(DeviceUtil.isRequestFloatPermission(activity));
                } else {
                    result.success(DeviceUtil.isRequestFloatPermission((Activity) context));
                }
                break;
            case "liveStatusChange":
                int statusValue = call.argument("status");
                Log.e(TAG, "liveStatusChange statusValue is " + values()[statusValue]);
                // 排除重复状态
                if (statusValue == status) {
                    result.success("");
                    return;
                }
                status = statusValue;
                if (floatView == null) {
                    Log.e(TAG, "[change state fail] floatView is null " + status);
                    /// 【2021 11.24】
                    result.success("");
                    return;
                }

                // Android端收到直播状态
                Log.e(TAG, "The Android terminal receives the live broadcast status:" + status);


                // 没有弹出悬浮窗，不更新悬浮窗UI
                if (!EasyFloat.isShow()) {
                    result.success("");
                    return;
                }

                /// 状态文字
                stateText = floatView.findViewById(R.id.state_text);
                handleState(status);

                LiveStatus inLiveStatus = values()[status];
                if (inLiveStatus == openLiveSuccess || inLiveStatus == playStreamSuccess || inLiveStatus == pushStreamSuccess) {
                    Log.e(TAG, "记录的isNotHandleLive条件达成，悬浮窗重新拉流");
                    ZegoExpressEngine engine = ZegoExpressEngine.getEngine();
                    if (engine != null) {
                        if (isAnchor && !isObs) {
                            engine.startPreview(previewCanvasFloat);
                        } else {
                            engine.startPlayingStream(roomId, previewCanvasFloat, getPullConfig());
                        }
                    }
                    isNotHandleLive = false;
                }
                result.success("");
                break;
            case "openPreview":

                mCaptureWidth = 0;
                mCaptureHeight = 0;

                openPreview();
                result.success("");
                break;
            case "open":

                roomId = call.argument("roomId");

                viewMode = call.argument("viewMode");

                isScreenSharing = call.argument("isScreenSharing");
                isObs = call.argument("isObs");
                isShowClose = call.argument("isShowClose");
                screenDirection = call.argument("screenDirection");

                mCaptureWidth = 0;
                mCaptureHeight = 0;

                open();
                Log.e(TAG, "悬浮窗功能 ==> open");
                result.success("");
                break;
            case "hide":
                EasyFloat.hide();
                Log.e(TAG, "悬浮窗功能 ==> hide");
                result.success("");
                break;
            case "changeViewMode":
                viewMode = call.argument("viewMode");

                changeViewMode();
                Log.e(TAG, "悬浮窗功能 ==> 浮窗更改 ==> " + viewMode);
                result.success("");
                break;
            case "screenDirectionChange":
                screenDirection = call.argument("screenDirection");

                screenDirectionChange();
                Log.e(TAG, "悬浮窗功能 ==> screenDirectionChange ==> " + screenDirection);
                result.success("");
                break;
            case "isShowFloat":
                result.success(EasyFloat.isShow());
                Log.e(TAG, "悬浮窗功能 ==> isShowFloat ==> " + EasyFloat.isShow());
                break;
            case "isRunningForeground":
                Activity okActivity = activity;

                result.success(isRunningForeground(okActivity));
                Log.e(TAG, "悬浮窗功能 ==> isRunningForeground ==> " + isRunningForeground(okActivity));
                break;
            case "dismiss":
                /// 重制直播状态为none
                status = 0;

                EasyFloat.dismiss();
                if (progressTimer != null) {
                    progressTimer.cancel();
                }
                Log.e(TAG, "悬浮窗功能 ==> dismiss");


                cancelAlertDialog();

                //关闭定时任务
                if (mCheckScreenSizeTimer != null) mCheckScreenSizeTimer.cancel();

                result.success("");
                break;
            case "initiativeCloseLive":
                if (clickStream != null) {
                    clickStream.success("close");
                }
                break;
            default: {
                result.notImplemented();
            }
        }
    }


    private static Disposable disposable;

    /**
     * 关闭提示对话框
     */
    private void cancelAlertDialog() {
        if (alertDialog != null && alertDialog.isShowing()) {
            alertDialog.dismiss();
            alertDialog = null;
        }
        /// 小窗显示时销毁显示对话框的计时器
        clickTimeCancel();
    }

    /**
     * 将本应用置顶到最前端
     * 当本应用位于后台时，则将它切换到最前端
     *
     * @param context
     */
    @SuppressLint("LongLogTag")
    public void setTopApp(Context context) {
        if (!isRunningForeground(context)) {

            Log.e(TAG, "没有打开app，setTopApp");

            /**获取ActivityManager*/
            ActivityManager activityManager = (ActivityManager) context.getSystemService(ACTIVITY_SERVICE);

            /**获得当前运行的task(任务)*/
            List<ActivityManager.RunningTaskInfo> taskInfoList = activityManager.getRunningTasks(100);
            for (ActivityManager.RunningTaskInfo taskInfo : taskInfoList) {
                /**找到本应用的 task，并将它切换到前台*/
                if (taskInfo.topActivity.getPackageName().equals(context.getPackageName())) {
                    disposable = Observable.intervalRange(1, 5, 0, 1, TimeUnit.SECONDS).subscribe(aLong -> {
                        if (isAppRunningForeground(context)) {
                            Log.e(TAG, "没有打开app，倒计时完了");
                            disposable.dispose();
                            sendCheckFloat();
                        } else {
                            Log.e(TAG, "没有打开app，尝试打开::" + aLong);
                            activityManager.moveTaskToFront(taskInfo.id, 0);

                            Timer timer1 = new Timer();//实例化Timer类
                            timer1.schedule(new TimerTask() {
                                @SuppressLint("LongLogTag")
                                public void run() {
                                    if (isAppRunningForeground(context)) {
                                        sendCheckFloat();
                                        Log.e(TAG, "打开app了，sendCheckFloat");

                                    }
                                    this.cancel();
                                }
                            }, 100);//毫秒
                        }
                    });
                    break;
                }
            }
        } else {
            clickStream.success("checkFloat;");
        }
    }

    public void sendCheckFloat() {
        /// 在主线程执行
        Activity okActivity = activity;
        okActivity.runOnUiThread(new Runnable() {
            public void run() {
                clickStream.success("checkFloat;");
            }
        });
    }

    /**
     * 判断本应用是否已经位于最前端
     *
     * @param context
     * @return 本应用已经位于最前端时，返回 true；否则返回 false
     */
    public static boolean isRunningForeground(Context context) {
        ActivityManager activityManager = (ActivityManager) context.getSystemService(Context.ACTIVITY_SERVICE);
        List<ActivityManager.RunningAppProcessInfo> appProcessInfoList = activityManager.getRunningAppProcesses();
        /**枚举进程*/
        for (ActivityManager.RunningAppProcessInfo appProcessInfo : appProcessInfoList) {
            if (appProcessInfo.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND) {
                if (appProcessInfo.processName.equals(context.getApplicationInfo().processName)) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * 打开预览悬浮窗
     */
    @SuppressLint("LongLogTag")
    private void openPreview() {
        Activity okPreViewActivity = activity;

        if (PermissionUtils.checkPermission(okPreViewActivity)) {
            Log.e(TAG, "checkPermission => 有权限，可以显示悬浮窗");


            showFloat(okPreViewActivity, R.layout.float_view, new OnFloatCallbacks() {
                @Override
                public void createdResult(boolean isCreated, @Nullable String msg, @Nullable View view) {
                    // 【APP】小窗口提示缺失
                    floatView = view;
                    previewFloat = floatView.findViewById(R.id.float_texture_view);
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                        previewFloat.setOutlineProvider(new TextureVideoViewOutlineProvider(16));
                        previewFloat.setClipToOutline(true);
                        floatView.setOutlineProvider(new TextureVideoViewOutlineProvider(16));
                        floatView.setClipToOutline(true);
                    }

                    previewCanvasFloat = new ZegoCanvas(previewFloat);
                    if (viewMode == 1) {
                        previewCanvasFloat.viewMode = ZegoViewMode.ASPECT_FILL;
                    } else {
                        previewCanvasFloat.viewMode = ZegoViewMode.ASPECT_FIT;
                    }

                    ZegoExpressEngine engine = ZegoExpressEngine.getEngine();
                    if (engine != null) {
                        engine.startPreview(previewCanvasFloat);
                    }
                    ImageView btClose = floatView.findViewById(R.id.bt_close);
                    /// 【2021 11.30】悬浮窗关闭按钮不为空才去设置事件，防止报错日志
                    if (btClose != null) {
                        btClose.setVisibility(View.VISIBLE);
                        btClose.setOnClickListener(new View.OnClickListener() {
                            @Override
                            public void onClick(View v) {
                                clickStream.success("preViewClose");
                            }
                        });
                    }


                    floatView.setBackgroundColor(0xffffffff);


                    floatView.setOnClickListener(new View.OnClickListener() {
                        @Override
                        public void onClick(View v) {
                            boolean isAppForeground = isAppRunningForeground(okPreViewActivity);
                            jumpToApp();
//                    if (!isAppForeground) {
//                        jumpToApp();
//                        // 仅返回app，不做跳转到预览页面[]
//
//                        // 如果在app外需要打开app且跳转直播预览页【10.11】
//                        clickStream.success("preViewLaunchApp;" + status);
//                        return;
//                    }
                            clickStream.success("preViewClick;" + status);
                            Log.e(TAG, "Click on the hover window， isAppForeground => " + isAppForeground);

                            if (isAppForeground) {
                                checkIsLaunch();
                            }
                        }
                    });
                }

                @Override
                public void show(@NonNull View view) {

                }

                @Override
                public void hide(@NonNull View view) {

                }

                @Override
                public void dismiss() {

                }

                @Override
                public void touchEvent(@NonNull View view, @NonNull MotionEvent event) {

                }

                @Override
                public void drag(@NonNull View view, @NonNull MotionEvent event) {

                }

                @Override
                public void dragEnd(@NonNull View view) {

                }
            });
            startCheckScreenSize();
        } else {
            DeviceUtil.jumpToSetting(okPreViewActivity);
        }
    }


    /// 再次检测是否启动app，防止小窗口消失后还没打开app
    private void checkIsLaunch() {
        Timer timer1 = new Timer();//实例化Timer类
        timer1.schedule(new TimerTask() {
            @SuppressLint("LongLogTag")
            public void run() {
                jumpToApp();
//                if (!isRunningForeground(context)) {
//                    jumpToApp();
//                    Log.e(TAG, "没有打开app，重新显示小窗口");
//                }
                this.cancel();
            }
        }, 300);//毫秒
    }

    /**
     * 改变视图模式
     */
    private void changeViewMode() {

        if (previewFloat == null) {
            previewFloat = floatView.findViewById(R.id.float_texture_view);
        }
        if (previewCanvasFloat == null) {
            previewCanvasFloat = new ZegoCanvas(previewFloat);
        }
        if (viewMode == 1) {
            previewCanvasFloat.viewMode = ZegoViewMode.ASPECT_FILL;
        } else {
            previewCanvasFloat.viewMode = ZegoViewMode.ASPECT_FIT;
        }

        ZegoExpressEngine engine = ZegoExpressEngine.getEngine();

        final boolean isPreview = isAnchor && !isObs;
        if (engine != null) {
            if (!isPreview) {
                // 画面会卡住
                engine.startPlayingStream(roomId, previewCanvasFloat, getPullConfig());
            }
        }

    }

    /**
     * 改变视图方向
     */
    private void screenDirectionChange() {


        int viewWidth = activity.getResources().getDimensionPixelSize(R.dimen.viewWidth);
        int viewHeight = activity.getResources().getDimensionPixelSize(R.dimen.viewHeight);

        if (previewFloat == null) {
            previewFloat = floatView.findViewById(R.id.float_texture_view);
        }
        if (previewCanvasFloat == null) {
            previewCanvasFloat = new ZegoCanvas(previewFloat);
        }

        //取控件当前的布局参数
        ViewGroup.LayoutParams params = (ViewGroup.LayoutParams) previewFloat.getLayoutParams();

        if (!screenDirection.equals("V")) {

//设置宽度值
            params.width = viewHeight;
//设置高度值
            params.height = viewWidth;
//使设置好的布局参数应用到控件
            previewFloat.setLayoutParams(params);


            if (!screenDirection.equals("RH")) {
                previewFloat.setRotation(90);
            } else {
                previewFloat.setRotation(270);
            }


            previewFloat.setClipToOutline(false);
        } else {

//设置宽度值
            params.width = viewWidth;
//设置高度值
            params.height = viewHeight;
//使设置好的布局参数应用到控件
            previewFloat.setLayoutParams(params);

            previewFloat.setRotation(0);
            previewFloat.setClipToOutline(true);
        }
    }

    /**
     * 获取拉流设置
     */
    @SuppressLint("LongLogTag")
    ZegoPlayerConfig getPullConfig() {
        ZegoPlayerConfig zegoPlayerConfig = new ZegoPlayerConfig();
        final String pullModeStr = MediaProjectionSetPlugin.pullModeStr;
        if (pullModeStr == null || pullModeStr.equals("") || pullModeStr.equals("RTC")) {
            zegoPlayerConfig.resourceMode = ZegoStreamResourceMode.ONLY_RTC;
        } else {
            zegoPlayerConfig.resourceMode = ZegoStreamResourceMode.ONLY_L3;
        }
        Log.e(TAG, "获取拉流设置::zegoPlayerConfig.resourceMode:" + zegoPlayerConfig.resourceMode);
        return zegoPlayerConfig;
    }

    /**
     * 打开悬浮窗
     */
    @SuppressLint("LongLogTag")
    private void open() {

        /// 打开悬浮窗时状态
        Log.e(TAG, "State " + status + " when you open the suspension window");

        if (isErrorStatus(status)) {
            Log.e(TAG, "打开直播间时为异常状态，记录isNotHandleLive");
            isNotHandleLive = true;
        }

        // 【2021 11.24】已经显示了，直接返回，防止出现画面卡住，
        // 操作步骤：1。点击分享按钮弹出；2。回到桌面；
        if (EasyFloat.isShow()) {
            Log.e(TAG, "已经显示了悬浮窗，不可再显示");
            return;
        }


        isAnchor = roomId == null || roomId.equals("");

        Activity okActivity = activity;

        if (PermissionUtils.checkPermission(okActivity)) {
            Log.e(TAG, "checkPermission => 有权限，可以显示悬浮窗");

            OnFloatCallbacks callbacks = new OnFloatCallbacks() {
                @Override
                public void dragEnd(@NonNull View view) {

                }

                @Override
                public void drag(@NonNull View view, @NonNull MotionEvent event) {

                }

                @Override
                public void touchEvent(@NonNull View view, @NonNull MotionEvent event) {

                }

                @Override
                public void dismiss() {

                }

                @Override
                public void hide(@NonNull View view) {

                }

                @Override
                public void show(@NonNull View view) {

                }

                @Override
                public void createdResult(boolean isCreated, @Nullable String msg, @Nullable View view) {
                    // 【APP】小窗口提示缺失
                    floatView = view;
                    setFloatViewHandle(okActivity, floatView);
                }
            };
            if (isScreenSharing && isAnchor) {
                showFloat(okActivity, R.layout.home_float, callbacks);
            } else {
                showFloat(okActivity, R.layout.float_view, callbacks);

            }
            startCheckScreenSize();
        } else {
            DeviceUtil.jumpToSetting(okActivity);
        }

    }

    private void setFloatViewHandle(Activity okActivity, View floatView) {

        if (isScreenSharing && isAnchor) {
            floatView.setBackgroundColor(ColorUtils.setAlphaComponent(0xff000000, 153));

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                FrameLayout floatBg = floatView.findViewById(R.id.float_bg);
                ViewOutlineProvider viewOutlineProvider = new ViewOutlineProvider() {
                    @Override
                    public void getOutline(View view, Outline outline) {
                        outline.setRoundRect(0,
                                0,
                                view.getWidth(),
                                view.getHeight(),
                                10);
                    }
                };
                floatBg.setOutlineProvider(viewOutlineProvider);
                floatBg.setClipToOutline(true);
                floatView.setOutlineProvider(viewOutlineProvider);
                floatView.setClipToOutline(true);
            }

        } else {
            final boolean isPreview = isAnchor && !isObs;

            ZegoExpressEngine engine = ZegoExpressEngine.getEngine();


            /// 如果不是预览的话【拉流】，则设置显示loading
            /// 停止推流是为了能收到首帧回调
            if (!isPreview) {
                /// 【2021 11.29】出现了拉流失败问题，暂时注释
//                    engine.stopPlayingStream(roomId);

                /// 打开悬浮窗，显示加载中
                Log.d(TAG, "Open suspension window to show loading");
                /// 【2021 11.29】出现了拉流失败问题，暂时注释
//                    handleRenderVideoFirstFrame();
            }

            previewFloat = floatView.findViewById(R.id.float_texture_view);
            progressBar1 = floatView.findViewById(R.id.progressBar1);
            /// 设置loading显示
            progressBar1.setVisibility(View.VISIBLE);

            progressTimer = new Timer();//实例化Timer类
            progressTimer.scheduleAtFixedRate(new TimerTask() {
                @SuppressLint("LongLogTag")
                public void run() {
                    /// 判断视图是否可用
                    if (previewFloat.isAvailable()) {
                        /// time为0则表示视图未显示，否则=表示视图显示
                        long time = previewFloat.getSurfaceTexture().getTimestamp();
                        Log.e(TAG, "getSurfaceTexture().getTimestamp：" + time);

                        /// 视图显示了，去掉加载中效果
                        if (time != 0) {
                            /// 在主线程执行
                            Activity okActivity = activity;
                            okActivity.runOnUiThread(new Runnable() {
                                public void run() {
                                    /// 设置加载中为不显示
                                    progressBar1.setVisibility(View.GONE);
                                }
                            });
                            /// 取消计时器
                            this.cancel();
                        }
                    }
                }
            }, 100, 100);//毫秒


            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP && !isObs) {
                previewFloat.setOutlineProvider(new TextureVideoViewOutlineProvider(16));
                previewFloat.setClipToOutline(true);
                floatView.setOutlineProvider(new TextureVideoViewOutlineProvider(16));
                floatView.setClipToOutline(true);
            }

            if (!screenDirection.equals("V")) {

                int viewWidth = activity.getResources().getDimensionPixelSize(R.dimen.viewWidth);
                int viewHeight = activity.getResources().getDimensionPixelSize(R.dimen.viewHeight);

                //取控件当前的布局参数
                ViewGroup.LayoutParams params = (ViewGroup.LayoutParams) previewFloat.getLayoutParams();
                //设置宽度值
                params.width = viewHeight;
                //设置高度值
                params.height = viewWidth;
                //使设置好的布局参数应用到控件
                previewFloat.setLayoutParams(params);

                if (!screenDirection.equals("RH")) {
                    previewFloat.setRotation(90);
                } else {
                    previewFloat.setRotation(270);
                }

                previewFloat.setClipToOutline(false);
            }

            // 蒙板
            bgBlack = floatView.findViewById(R.id.bg_black);
            bgBlack.setBackgroundColor(ColorUtils.setAlphaComponent(0xff000000, 153));
            bgBlack.setVisibility(View.GONE);

            previewCanvasFloat = new ZegoCanvas(previewFloat);
            if (viewMode == 1) {
                previewCanvasFloat.viewMode = ZegoViewMode.ASPECT_FILL;
            } else {
                previewCanvasFloat.viewMode = ZegoViewMode.ASPECT_FIT;
            }

            /// 【APP】主播杀掉APP进程，观众显示主播暂时离开。观众小窗口白屏
            if (!isNotHandleLive) {
                if (engine != null) {
                    if (isPreview) {
                        engine.startPreview(previewCanvasFloat);
                    } else {
                        engine.startPlayingStream(roomId, previewCanvasFloat, getPullConfig());
                    }
                }
            } else {
                /// 状态文字
                stateText = floatView.findViewById(R.id.state_text);
                handleState(status);
            }
            if (isShowClose) {
                if (!isAnchor) {
                    ImageView btClose = floatView.findViewById(R.id.bt_close);
                    btClose.setVisibility(View.VISIBLE);
                    btClose.setOnClickListener(new View.OnClickListener() {
                        @Override
                        public void onClick(View v) {
                            /// 重制直播状态为none
                            status = 0;

                            clickStream.success("close");
                        }
                    });
                }
            }

            floatView.setBackgroundColor(0xffffffff);

        }

        floatView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                boolean isAppForeground = isAppRunningForeground(okActivity);
                jumpToApp();
//                    if (!isAppForeground) {
//                        jumpToApp();
//                        // 仅返回app，不做跳转到直播页面[]
//
//                        // 如果在app外需要打开app且跳转直播页【10.27】
//                        clickStream.success("launchApp;" + status);
//                        return;
//                    }
                clickStream.success("click;" + status);
                Log.e(TAG, "Click on the hover window， isAppForeground => " + isAppForeground);

                if (isAppForeground) {
                    checkIsLaunch();
                }
            }
        });
    }

    @SuppressLint("LongLogTag")
    private void startCheckScreenSize() {
        Timer timer1 = new Timer();//实例化Timer类
        timer1.schedule(new TimerTask() {
            @SuppressLint("LongLogTag")
            public void run() {
                startCheckScreenSizeHandle();
                this.cancel();
            }
        }, 500);//毫秒

    }

    @SuppressLint("LongLogTag")
    private void startCheckScreenSizeHandle() {
        Log.e(TAG, "【悬浮窗】开始轮训屏幕尺寸");
        mCheckScreenSizeTimer = new Timer();
        //在此添加轮询
        TimerTask mTimerTask = new TimerTask() {
            @Override
            public void run() {
                //在此添加轮询
                refreshSize();
            }
        };
        mCheckScreenSizeTimer.schedule(mTimerTask, DELAY, PERIOD);
    }


    @SuppressLint("LongLogTag")
    void refreshSize() {
        int oloWidth = mCaptureWidth;
        int oldHeight = mCaptureHeight;

        DisplayMetrics displayMetrics = new DisplayMetrics();

        WindowManager mWindowManager = (WindowManager) context.getSystemService(Context.WINDOW_SERVICE);
        mWindowManager.getDefaultDisplay().getRealMetrics(displayMetrics);
        mCaptureWidth = displayMetrics.widthPixels;
        mCaptureHeight = displayMetrics.heightPixels;

        if (mCaptureHeight == oldHeight && mCaptureWidth == oloWidth) {
            return;
        }

        if (EasyFloat.isShow()) {
            Log.e(TAG, "【悬浮窗】尺寸变更了，更新悬浮窗");
            EasyFloat.updateFloat();
        }
    }

    //弹出提示框
    private void showDialog(Activity okActivity) {
        alertDialog = new AlertDialog.Builder(okActivity, R.style.Theme_AppCompat_Light_Dialog_Alert)
                .setMessage("无法回到直播间，请手动切换APP应用回到直播间。")
                .setTitle("提示")
                .setPositiveButton("确定", new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialog, int which) {
                        dialog.dismiss();
                    }
                })
                .setCancelable(false)
                .create();
        //8.0系统加强后台管理，禁止在其他应用和窗口弹提醒弹窗，如果要弹，必须使用TYPE_APPLICATION_OVERLAY
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            alertDialog.getWindow().setType((WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY));
        } else {
            alertDialog.getWindow().setType((WindowManager.LayoutParams.TYPE_SYSTEM_ALERT));
        }
        alertDialog.show();

        /// 设置对话框宽度【2022 01.07】
        /// 【APP】点击小窗无法回到直播间提示显示不全
        DisplayMetrics displayMetrics = new DisplayMetrics();
        WindowManager mWindowManager = (WindowManager) context.getSystemService(Context.WINDOW_SERVICE);
        mWindowManager.getDefaultDisplay().getRealMetrics(displayMetrics);
        mCaptureWidth = displayMetrics.widthPixels;
        mCaptureHeight = displayMetrics.heightPixels;
        WindowManager.LayoutParams params = alertDialog.getWindow().getAttributes();
        if (mCaptureWidth > mCaptureHeight) {
            params.width = mCaptureHeight - 150;
        } else {
            params.width = mCaptureWidth - 150;
        }
        alertDialog.getWindow().setLayout(params.width, params.height);
    }


    /**
     * [获取应用程序版本名称信息]
     *
     * @param context
     * @return 当前应用的版本名称
     */
    public static synchronized String getPackageName(Context context) {
        try {
            PackageManager packageManager = context.getPackageManager();
            PackageInfo packageInfo = packageManager.getPackageInfo(
                    context.getPackageName(), 0);
            return packageInfo.packageName;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    private void doStartApplicationWithPackageName(String packagename) {

        // 通过包名获取此APP详细信息，包括Activities、services、versioncode、name等等
        PackageInfo packageinfo = null;
        try {
            packageinfo = activity.getPackageManager().getPackageInfo(packagename, 0);
        } catch (PackageManager.NameNotFoundException e) {
            e.printStackTrace();
        }
        if (packageinfo == null) {
            return;
        }

        // 创建一个类别为CATEGORY_LAUNCHER的该包名的Intent
        Intent resolveIntent = new Intent(Intent.ACTION_MAIN, null);
        resolveIntent.addCategory(Intent.CATEGORY_LAUNCHER);
        resolveIntent.setPackage(packageinfo.packageName);

        // 通过getPackageManager()的queryIntentActivities方法遍历
        List<ResolveInfo> resolveinfoList = activity.getPackageManager()
                .queryIntentActivities(resolveIntent, 0);

        ResolveInfo resolveinfo = resolveinfoList.iterator().next();
        if (resolveinfo != null) {
            // packagename = 参数packname
            String packageName = resolveinfo.activityInfo.packageName;
            // 这个就是我们要找的该APP的LAUNCHER的Activity[组织形式：packagename.mainActivityname]
            String className = resolveinfo.activityInfo.name;
            // LAUNCHER Intent
            Intent intent = new Intent(Intent.ACTION_MAIN);
            intent.addCategory(Intent.CATEGORY_LAUNCHER);

            // 设置ComponentName参数1:packagename参数2:MainActivity路径
            ComponentName cn = new ComponentName(packageName, className);

            intent.setComponent(cn);
            activity.startActivity(intent);
        }
    }

    private void jumpToApp() {
        RomUtils romUtils = new RomUtils();
        Log.e("Q1", "romUtils.isBackgroundStartAllowed(context)::" + romUtils.isBackgroundStartAllowed(context));
        Log.e("Q1", "getPackageName(context)::" + getPackageName(context));

        // 回到app
        Intent intent = new Intent(activity, MainActivity.class);
        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        activity.getApplicationContext().startActivity(intent);
        // 使用包名方式回到app，防止出现 【APP】红米note4X小窗口问题
//        doStartApplicationWithPackageName(getPackageName(context));
//        com.example.flutter_fanbook_live.ReifiedKt.startActivity<MainActivity>(activity);

        /// 判断是否可以悬浮窗打开app方案2：
        /// 直接去打开，500毫秒后没打开就是打不开了，弹出提示，也不去隐藏小窗，因为权限允许后自然可以小窗打开app
        clickTimeCancel();
        clickTimer = new Timer();//实例化Timer类
        /// 延迟显示对话框的时间，单位毫秒
        final int showDialogDelay = 5000;
        clickTimer.schedule(new TimerTask() {
            @SuppressLint("LongLogTag")
            public void run() {
                /// 【2021 12.28】点击小窗时防止【后台弹出应用】权限的手机也弹出了提示
                if (!isAppRunningForeground(context)) {

                    Log.e("Q1", "没有允许权限，弹出设置页面");
                    /// 在主线程执行
                    Activity okActivity = activity;
                    okActivity.runOnUiThread(new Runnable() {
                        public void run() {
                            showDialog(activity);
                        }
                    });

                } else {
                    cancelAlertDialog();
                }
                clickTimeCancel();
            }
        }, showDialogDelay);//毫秒
        /// 就在显示之后去检测
        Timer timer2 = new Timer();//实例化Timer类
        timer2.schedule(new TimerTask() {
            @SuppressLint("LongLogTag")
            public void run() {
                if (isAppRunningForeground(context)) {
                    cancelAlertDialog();
                }
                this.cancel();
            }
        }, showDialogDelay + 100);//毫秒
    }

    /**
     * 取消点击小窗的计时器
     */
    void clickTimeCancel() {
        if (clickTimer != null) {
            clickTimer.cancel();
            clickTimer = null;
        }
    }

    @SuppressLint("LongLogTag")
    private void showFloat(Activity okActivity, int layoutId, OnFloatCallbacks callbacks) {
        /// 优化小窗口位置（安卓苹果统一）
        WindowManager manager = okActivity.getWindowManager();
        DisplayMetrics outMetrics = new DisplayMetrics();
        manager.getDefaultDisplay().getMetrics(outMetrics);
        int height2 = outMetrics.heightPixels;
        int floatHeight = okActivity.getResources().getDimensionPixelSize(R.dimen.floatHeight);
        int bottomMargin = okActivity.getResources().getDimensionPixelSize(R.dimen.bottomMargin);


        EasyFloat.with(okActivity).setLayout(layoutId).setShowPattern(ShowPattern.ALL_TIME)
                // 设置吸附方式，共15种模式，详情参考SidePattern
                .setSidePattern(SidePattern.RESULT_HORIZONTAL)
                // 设置浮窗是否可拖拽
                .setDragEnable(true)
                // 浮窗是否包含EditText，默认不包含
                .hasEditText(false)
                // 设置浮窗的对齐方式和坐标偏移量
                .setGravity(Gravity.END, 0, (height2) - floatHeight - (bottomMargin / 2))
                // 设置当布局大小变化后，整体view的位置对齐方式
                .setLayoutChangedGravity(Gravity.END)
                // 设置浮窗的出入动画，可自定义，实现相应接口即可（策略模式），无需动画直接设置为null
                .setAnimator(null).registerCallbacks(
                callbacks
        )
                // ps：通过Kotlin DSL实现的回调，可以按需复写方法，用到哪个写哪个
                .show();
    }
}
