package com.idreamsky.buff.live;

import androidx.annotation.ColorInt;
import androidx.annotation.IntRange;

public final class ColorUtils {

    @ColorInt
    public static int setAlphaComponent(@ColorInt int color, @IntRange(from = 0L, to = 255L) int alpha) {
        if (alpha >= 0 && alpha <= 255) {
            return color & 16777215 | alpha << 24;
        } else {
            throw new IllegalArgumentException("alpha must be between 0 and 255.");
        }
    }

}