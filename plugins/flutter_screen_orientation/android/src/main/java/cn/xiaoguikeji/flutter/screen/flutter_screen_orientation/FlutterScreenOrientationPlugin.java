package cn.xiaoguikeji.flutter.screen.flutter_screen_orientation;

import android.content.Context;
import android.hardware.SensorManager;
import android.os.Build;
import android.provider.Settings;
import android.view.OrientationEventListener;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** FlutterScreenOrientationPlugin */
public class FlutterScreenOrientationPlugin implements FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;
  private OrientationEventListener mOrientationListener;
  private Context context;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    context = flutterPluginBinding.getApplicationContext();
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "flutter_screen_orientation");
    channel.setMethodCallHandler(this);
  }
  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (call.method.equals("init")) {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.CUPCAKE) {
        mOrientationListener = new OrientationEventListener(context,
                SensorManager.SENSOR_DELAY_NORMAL) {
          @Override
          public void onOrientationChanged(int orientation) {
            //如果当前开启了竖屏锁定，则不回调
            int flag = Settings.System.getInt(context.getContentResolver(),
                    Settings.System.ACCELEROMETER_ROTATION, 1);
            if(flag != 1){
              return;
            }
            if (orientation == OrientationEventListener.ORIENTATION_UNKNOWN) {
              return;  //手机平放时，检测不到有效的角度
            }
            //可以根据不同角度检测处理，这里只检测四个角度的改变
            if (orientation > 350 || orientation < 10) { //0度
              //摄像头朝上
              channel.invokeMethod("orientationCallback","1");
            } else if (orientation > 80 && orientation < 100) { //90度
              //摄像头朝右
              channel.invokeMethod("orientationCallback","4");
            } else if (orientation > 170 && orientation < 190) { //180度
              //摄像头朝下
              channel.invokeMethod("orientationCallback","2");
            } else if (orientation > 260 && orientation < 280) { //270度
              //摄像头朝左
              channel.invokeMethod("orientationCallback","3");
            }
          }
        };
        if (mOrientationListener.canDetectOrientation()) {
          mOrientationListener.enable();
        } else {
          mOrientationListener.disable();
        }
      }

    } else {
      result.notImplemented();
    }

  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.CUPCAKE) {
      mOrientationListener.disable();
    }
  }
}
