package com.idreamsky.buff;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;

/**
 * 当启动页设置成singleTask时，带来的一个严重性问题就是:
 * 处于活动中的（顶层可见）视图（非启动页）切到后台再切回前台，活动页会消失，并且显示启动页
 * 为了兼容中台那边的情况，目前这边MainActivity最好不要动singleTask这个启动模式设置
 *
 * 具体解决方案参考: https://www.jianshu.com/p/dde817f9ea1a
 */
public class FakeLaunchActivity extends Activity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (!isTaskRoot()) {
            Intent intent = getIntent();
            if (intent != null) {
                if (intent.hasCategory(Intent.CATEGORY_LAUNCHER) && Intent.ACTION_MAIN.equals(intent.getAction())) {
                    finish();
                    return;
                }
            }
        }
        Intent intent = new Intent(this, MainActivity.class);
        startActivity(intent);
        finish();
    }
}
