package com.ms.sdk.plugin.privace.util;

/**
 * @author Lody
 */

public class ObjectsCompat {

	/**
	 * Null-safe equivalent of {@code a.equals(b)}.
	 */
	public static boolean equals(Object a, Object b) {
		return (a == null) ? (b == null) : a.equals(b);
	}
}
