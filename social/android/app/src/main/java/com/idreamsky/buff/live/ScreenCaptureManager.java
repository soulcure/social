package com.idreamsky.buff.live;

import android.annotation.SuppressLint;
import android.content.Context;
import android.graphics.SurfaceTexture;
import android.hardware.display.DisplayManager;
import android.hardware.display.VirtualDisplay;
import android.media.projection.MediaProjection;
import android.os.Build;
import android.os.Handler;
import android.os.HandlerThread;
import android.util.DisplayMetrics;
import android.view.Surface;
import android.view.WindowManager;

import androidx.annotation.RequiresApi;

import org.apache.http.HttpResponse;
import org.apache.http.NameValuePair;
import org.apache.http.client.HttpClient;
import org.apache.http.client.entity.UrlEncodedFormEntity;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.message.BasicNameValuePair;
import org.apache.http.util.EntityUtils;

import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.util.ArrayList;
import java.util.List;
import java.util.Timer;
import java.util.TimerTask;

import im.zego.zego_express_engine.IZegoFlutterCustomVideoCaptureHandler;
import im.zego.zego_express_engine.ZegoCustomVideoCaptureManager;
import im.zego.zego_express_engine.internal.ZegoLog;
import im.zego.zegoexpress.ZegoExpressEngine;
import im.zego.zegoexpress.constants.ZegoPublishChannel;
import im.zego.zegoexpress.entity.ZegoVideoConfig;
import io.flutter.Log;

public class ScreenCaptureManager implements IZegoFlutterCustomVideoCaptureHandler {

    @SuppressLint("StaticFieldLeak")
    private static ScreenCaptureManager instance;

    private MediaProjection mMediaProjection = null;

    private volatile VirtualDisplay mVirtualDisplay = null;

    private volatile int mCaptureWidth;

    private volatile int mCaptureHeight;

    private Context mContext;

    private HandlerThread mHandlerThread = null;

    private Handler mHandler = null;

    private volatile Surface mSurface = null;

    private volatile boolean isCapturing = false;

    private WindowManager mWindowManager;

    private static final int PERIOD = 600;
    private static final int DELAY = 50;
    private Timer mCheckScreenSizeTimer;

    private final String TAG = "ScreenCaptureManager";

    private final HttpClient client = HttpClients.createDefault();

    public static ScreenCaptureManager getInstance() {
        if (instance == null) {
            synchronized (ScreenCaptureManager.class) {
                if (instance == null) {
                    instance = new ScreenCaptureManager();
                }
            }
        }
        return instance;
    }

    public void init(Context context, MediaProjection mediaProjection) {
        mContext = context;
        mMediaProjection = mediaProjection;
        Log.e(TAG, "【屏幕共享】setScreenCaptureInfo设置屏幕共享信息");
    }

    private void startCheckScreenSize() {
        Log.e(TAG, "【屏幕共享】开始检测屏幕尺寸");
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

    /**
     * 刷新
     */
    @RequiresApi(api = Build.VERSION_CODES.JELLY_BEAN_MR1)
    void refreshSize() {
        int oloWidth = mCaptureWidth;
        int oldHeight = mCaptureHeight;

        DisplayMetrics displayMetrics = new DisplayMetrics();

        mWindowManager.getDefaultDisplay().getRealMetrics(displayMetrics);
        mCaptureWidth = displayMetrics.widthPixels;
        mCaptureHeight = displayMetrics.heightPixels;

        if (mCaptureHeight == oldHeight && mCaptureWidth == oloWidth) {
            return;
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            if (mCaptureWidth > mCaptureHeight) {
                Log.e(TAG, "【屏幕共享】轮训到了屏幕旋转为横屏，宽大于高了");
            } else {
                Log.e(TAG, "【屏幕共享】轮训到了屏幕旋转为竖屏");
            }
            setResolution(mCaptureWidth, mCaptureHeight);
        }
    }

    void postSizeToHttp(int width, int height) {

        //请求参数信息
        String token = MediaProjectionSetPlugin.token;
        String roomId = MediaProjectionSetPlugin.roomId;
        if (MediaProjectionSetPlugin.liveHost == null || MediaProjectionSetPlugin.liveHost == "") {
            ZegoLog.log("live host null!!!");
            return;
        }
        String url = MediaProjectionSetPlugin.liveHost + "/v1/live/update_mix";
        ZegoLog.log("livehost url::" + url);
        //post请求
        HttpPost post = new HttpPost(url);

        //  todo 设置连接超时时间和发送时间
        // 先注释，开启会导致掉线，httpClient错误
//        client.getParams().setParameter(CoreConnectionPNames.CONNECTION_TIMEOUT,
//                3000
//        );
//        client.getParams().setParameter(CoreConnectionPNames.SO_TIMEOUT,
//                5000
//        );

        // 构建请求参数
        List<NameValuePair> params = new ArrayList<>();
        params.add(new BasicNameValuePair("token", token));
        params.add(new BasicNameValuePair("roomId", roomId));

        //  横屏【经过换算】
        if (width > height) {
            params.add(new BasicNameValuePair("width", String.valueOf(720 * width / height)));
            params.add(new BasicNameValuePair("height", String.valueOf(720)));
        } else {
            params.add(new BasicNameValuePair("width", String.valueOf(720)));
            params.add(new BasicNameValuePair("height", String.valueOf(720 * height / width)));
        }

        //请求体
        try {
            post.setHeader("Authentication", token);
            post.setEntity(new UrlEncodedFormEntity(params));
        } catch (UnsupportedEncodingException unsupportedEncodingException) {
            unsupportedEncodingException.printStackTrace();
        }

        // Android 4.0 之后不能在主线程中请求HTTP请求
        new Thread(() -> {
            //执行请求
            /// 直播相关bugly问题总结【1】
            HttpResponse response;
            try {
                response = client.execute(post);

                /// 直播相关bugly问题总结【1】
                /// 获取结果
                int statusCode = response.getStatusLine().getStatusCode();
                if (statusCode == 200) {
                    String result = null;
                    try {
                        result = EntityUtils.toString(response.getEntity());
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                    Log.e(TAG, "url：" + url);
                    Log.e(TAG, "请求参数::" + params);
                    Log.e(TAG, "返回结果::" + result);
                }
            } catch (IOException ioException) {
                ioException.printStackTrace();
            }

        }).start();

    }

    @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
    public synchronized void setResolution(int width, int height) {
        ZegoLog.log("监听屏幕旋转  setListener width::" + width);

        postSizeToHttp(width, height);

        if (mVirtualDisplay != null) {
            mVirtualDisplay.release();
            Log.e(TAG, "【屏幕共享】屏幕共享旋转了，mVirtualDisplay释放结果:" + !mVirtualDisplay.getDisplay().isValid());
            mVirtualDisplay = null;
        }
        SurfaceTexture texture = ZegoExpressEngine.getEngine().getCustomVideoCaptureSurfaceTexture(ZegoPublishChannel.AUX);
        texture.setDefaultBufferSize(width, height);

        mSurface = new Surface(texture);
        Log.e(TAG, "【屏幕共享】setResolution传数据");
        mVirtualDisplay = mMediaProjection.createVirtualDisplay("ScreenCapture",
                width, height, 1,
                DisplayManager.VIRTUAL_DISPLAY_FLAG_PUBLIC, mSurface, null, mHandler);
        mVirtualDisplay.setSurface(mSurface);
        mVirtualDisplay.resize(width, height, 1);

        /// 设置视频配置-修复Android屏幕共享画面模糊
        setVideoConfig(width, height);
    }

    /**
    * 修改视频配置
    */
    private void setVideoConfig(int width, int height) {
        ZegoVideoConfig config = new ZegoVideoConfig();
        config.setEncodeResolution(width, height);
        config.setVideoFPS(25);
        config.setVideoBitrate(2000);

        ZegoExpressEngine.getEngine().setVideoConfig(config, ZegoPublishChannel.AUX);
    }

    @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
    public synchronized void startCapture(int channel) {
        Log.e(TAG, "【屏幕共享】开启屏幕数据捕捉startCapture");

        if (isCapturing) {
            Log.e(TAG, "【屏幕共享】isCapturing为true，正在捕捉屏幕，先停止，再重新开启");
            stopCapture(false);
        }


        /// 尺寸相关-防止出现断网重连后尺寸还是上次的
        DisplayMetrics displayMetrics = new DisplayMetrics();
        mWindowManager = (WindowManager) mContext.getSystemService(Context.WINDOW_SERVICE);
        mWindowManager.getDefaultDisplay().getRealMetrics(displayMetrics);
        mCaptureWidth = displayMetrics.widthPixels;
        mCaptureHeight = displayMetrics.heightPixels;
        postSizeToHttp(mCaptureWidth, mCaptureHeight);
        Log.d(TAG, "mCaptureWidth::" + mCaptureWidth);
        Log.d(TAG, "mCaptureHeight::" + mCaptureHeight);


        SurfaceTexture texture = ZegoCustomVideoCaptureManager.getInstance().getSurfaceTexture(channel);
        texture.setDefaultBufferSize(mCaptureWidth, mCaptureHeight);
        mSurface = new Surface(texture);

        mHandlerThread = new HandlerThread("ZegoScreenCapture");
        mHandlerThread.start();
        mHandler = new Handler(mHandlerThread.getLooper());


        Log.e(TAG, "【屏幕共享】startCapture传数据");

        /// 塞数据到sdk
        mVirtualDisplay = mMediaProjection.createVirtualDisplay("ScreenCapture",
                mCaptureWidth,
                mCaptureHeight,
                1,
                DisplayManager.VIRTUAL_DISPLAY_FLAG_PUBLIC,
                /// 设置mSurface代表传数据到zego自定义采集
                /// 设置为null代表不传屏幕数据给zego画面，观众端收到的会是黑色的
                mSurface,
                null,
                mHandler);

        /// 设置视频配置
        setVideoConfig(mCaptureWidth, mCaptureHeight);

        Log.e(TAG, "【屏幕共享】mSurface.toString()::" + mSurface.toString());

        isCapturing = true;

        startCheckScreenSize();
    }

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    public void stopCapture(boolean stop) {
        Log.e(TAG, "【屏幕共享】stopCapture");
        if (!isCapturing) {
            Log.e(TAG, "【屏幕共享】已经停止了，直接返回");
            return;
        }

        isCapturing = false;

        //关闭定时任务
        if (mCheckScreenSizeTimer != null) mCheckScreenSizeTimer.cancel();

        if (mVirtualDisplay != null) {
            mVirtualDisplay.release();
            Log.e(TAG, "【屏幕共享】屏幕共享旋转了，mVirtualDisplay释放结果:" + !mVirtualDisplay.getDisplay().isValid());
            mVirtualDisplay = null;
        }

        if (mSurface != null) {
            mSurface.release();
            mSurface = null;
        }

        if (mHandlerThread != null) {
            mHandlerThread.quit();
            mHandlerThread = null;
            mHandler = null;
        }
    }

    @Override
    public void onStart(int channel) {

        Log.e(TAG, "【屏幕共享】zego调用开始开始-onStart");

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            startCapture(channel);
        } else {
            Log.w("ZEGO", "The minimum system API level required for screen capture is 21");
        }
    }

    @Override
    public void onStop(int channel) {
        Log.e(TAG, "【屏幕共享】onStop");
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            stopCapture(true);
        } else {
            Log.w("ZEGO", "The minimum system API level required for screen capture is 21");
        }
    }

    public VirtualDisplay getVirtualDisplay() {
        return mVirtualDisplay;
    }
}