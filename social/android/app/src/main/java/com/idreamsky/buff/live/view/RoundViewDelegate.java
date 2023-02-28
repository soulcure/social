package com.idreamsky.buff.live.view;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.PorterDuff;
import android.graphics.PorterDuffXfermode;
import android.graphics.RectF;
import android.view.View;

/**
 * 圆角View 代理
 *如果想改为圆形view，修改rect_adius为很大的数字，比如10000
 */
public class RoundViewDelegate{
    private final RectF roundRect = new RectF();
    private float rect_adius = 16;  //单位为像素
    private final Paint maskPaint = new Paint();
    private final Paint zonePaint = new Paint();
    private View mView;
    private Context mContext;

    public RoundViewDelegate(View view, Context context){
        this.mView = view;
        this.mContext = context;
        init();
    }

    private void init(){
        maskPaint.setAntiAlias(true);
        maskPaint.setXfermode(new PorterDuffXfermode(PorterDuff.Mode.SRC_IN));
        //
        zonePaint.setAntiAlias(true);
        zonePaint.setColor(Color.WHITE);
    }

    /**
     * 从新设置圆角
     * @param adius
     */
    public void setRectAdius(float adius) {
        rect_adius = adius;
        if(mView != null){
            mView.invalidate();
        }
    }

    /**
     * 圆角区域设置
     * @param width
     * @param height
     */
    public void roundRectSet(int width,int height){
        roundRect.set(0, 0, width, height);
    }

    /**
     * 画布区域裁剪
     * @param canvas
     */
    public void canvasSetLayer(Canvas canvas){
        canvas.saveLayer(roundRect, zonePaint, Canvas.ALL_SAVE_FLAG);
        canvas.drawRoundRect(roundRect, rect_adius, rect_adius, zonePaint);
        //
        canvas.saveLayer(roundRect, maskPaint, Canvas.ALL_SAVE_FLAG);
    }
}