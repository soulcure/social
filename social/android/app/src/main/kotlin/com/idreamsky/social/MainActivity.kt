import android.content.pm.PackageManager.GET_META_DATA
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channel = "samples.flutter.channel"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel).setMethodCallHandler { call, result ->
            if (call.method == "getChannelValue") {
                val packageInfo = packageManager.getActivityInfo(componentName, GET_META_DATA)
                val value = packageInfo.metaData.getString("channelValue")
                if(value != null) result.success(value)
                else result.error("default","default","default")
            } else {
                result.notImplemented()
            }
        }
    }

}