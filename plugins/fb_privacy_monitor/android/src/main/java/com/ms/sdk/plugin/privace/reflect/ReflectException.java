package com.ms.sdk.plugin.privace.reflect;

/**
 * author: leevin.li
 * date:  On 2018/9/25.
 */

public class ReflectException extends RuntimeException {

    public ReflectException(String message, Throwable cause) {
        super(message, cause);
    }

    public ReflectException(Throwable cause) {
        super(cause);
    }
}
