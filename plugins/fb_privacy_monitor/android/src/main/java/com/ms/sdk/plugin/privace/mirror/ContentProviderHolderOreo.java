package com.ms.sdk.plugin.privace.mirror;

import android.content.pm.ProviderInfo;
import android.os.IInterface;

import com.ms.sdk.plugin.privace.reflect.RefBoolean;
import com.ms.sdk.plugin.privace.reflect.RefClass;
import com.ms.sdk.plugin.privace.reflect.RefObject;

/**
 * @author Lody
 */

public class ContentProviderHolderOreo {
    public static Class<?> TYPE = RefClass.load(ContentProviderHolderOreo.class, "android.app.ContentProviderHolder");
    public static RefObject<ProviderInfo> info;
    public static RefObject<IInterface> provider;
    public static RefBoolean noReleaseNeeded;
}
