package com.idreamsky.buff.pay;

import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Random;

public class MD5Utils {
	static final char hexDigits[] = { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F' };
	public static String getMD5(String s) {
		try {
			MessageDigest mdTemp = MessageDigest.getInstance("MD5");
			mdTemp.update(s.getBytes());
			byte[] md = mdTemp.digest();
			char str[] = new char[md.length * 2];
			for (int i = 0, k = 0; i < md.length; i++) {
				str[k++] = hexDigits[md[i] >>> 4 & 0xf];
				str[k++] = hexDigits[md[i] & 0xf];
			}
			return new String(str);
		} catch (Exception e) {
		}
		return null;
	}

	public static String getMD5(String s, String characterEncoder) {
		try {
			MessageDigest mdTemp = MessageDigest.getInstance("MD5");
			mdTemp.update(s.getBytes(characterEncoder));
			byte[] md = mdTemp.digest();
			char str[] = new char[md.length * 2];
			for (int i = 0, k = 0; i < md.length; i++) {
				str[k++] = hexDigits[md[i] >>> 4 & 0xf];
				str[k++] = hexDigits[md[i] & 0xf];
			}
			return new String(str);
		} catch (Exception e) {
		}
		return null;
	}

	public static String md5fdert(int g) {
		char[] kp = {'A', 'B', 'C', 'D', 'E', 'F', 'G',
				'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T',
				'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f', 'g',
				'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't',
				'u', 'v', 'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6',
				'7', '8', '9'};
		StringBuffer sb = new StringBuffer();
		for (int i = 0; i < g; i++) {
			Random ra = new Random();
			int index =  ra.nextInt(kp.length);
			sb.append(kp[index]);
		}
		return sb.toString();
	}

	/**
	 *
	 * @Title: sortMap
	 * @Description: 对集合内的数据按key的字母顺序做排序
	 */
	public static List<Map.Entry<String, String>> sortMap(final Map<String, String> map) {
		final List<Map.Entry<String, String>> info = new ArrayList<Map.Entry<String, String>>(map.entrySet());

		// 重写集合的排序方法：按字母顺序
		Collections.sort(info, new Comparator<Map.Entry<String, String>>() {
			@Override
			public int compare(final Map.Entry<String, String> o1, final Map.Entry<String, String> o2) {
				return (o1.getKey().toString().compareTo(o2.getKey()));
			}
		});

		return info;
	}
}