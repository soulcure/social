package com.idreamsky.buff.wxapi;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;

import com.idreamsky.buff.MainActivity;
import com.tencent.mm.opensdk.constants.ConstantsAPI;
import com.tencent.mm.opensdk.modelbase.BaseReq;
import com.tencent.mm.opensdk.modelbase.BaseResp;
import com.tencent.mm.opensdk.modelbiz.WXLaunchMiniProgram;
import com.tencent.mm.opensdk.modelmsg.ShowMessageFromWX;
import com.tencent.mm.opensdk.openapi.IWXAPI;
import com.tencent.mm.opensdk.openapi.IWXAPIEventHandler;
import com.tencent.mm.opensdk.openapi.WXAPIFactory;
import com.tencent.mm.opensdk.utils.Log;

import org.json.JSONException;
import org.json.JSONObject;

import java.lang.ref.WeakReference;

public class WXEntryActivity extends Activity implements IWXAPIEventHandler {
	private static final String TAG = "FbPayUtil-wx";

	private IWXAPI api;
	private MyHandler handler;

	private static class MyHandler extends Handler {
		private final WeakReference<WXEntryActivity> wxEntryActivityWeakReference;

		public MyHandler(com.idreamsky.buff.wxapi.WXEntryActivity wxEntryActivity) {
			wxEntryActivityWeakReference = new WeakReference<WXEntryActivity>(wxEntryActivity);
		}

		@Override
		public void handleMessage(Message msg) {
			int tag = msg.what;
			switch (tag) {
				case 1: {
					Bundle data = msg.getData();
					JSONObject json = null;
					try {
						json = new JSONObject(data.getString("result"));
						String openId, accessToken, refreshToken, scope;
						openId = json.getString("openid");

						accessToken = json.getString("access_token");
						refreshToken = json.getString("refresh_token");
						scope = json.getString("scope");
						Log.i(TAG, json.toString());
						Log.i(TAG, openId);
						Log.i(TAG, accessToken);
						Log.i(TAG, refreshToken);
						Log.i(TAG, scope);
						Intent intent = new Intent(wxEntryActivityWeakReference.get(), MainActivity.class);
						intent.putExtra("openId", openId);
						intent.putExtra("accessToken", accessToken);
						intent.putExtra("refreshToken", refreshToken);
						intent.putExtra("scope", scope);
						wxEntryActivityWeakReference.get().startActivity(intent);
					} catch (JSONException e) {
						Log.e(TAG, e.getMessage());
					}
				}
			}
		}
	}

	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);

		api = WXAPIFactory.createWXAPI(this, "wx5a6ce7e89c14128d", false);
		handler = new MyHandler(this);

		try {
			Intent intent = getIntent();
			api.handleIntent(intent, this);
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	@Override
	protected void onNewIntent(Intent intent) {
		super.onNewIntent(intent);

		setIntent(intent);
		api.handleIntent(intent, this);
	}

	@Override
	public void onReq(BaseReq baseReq) {
		Log.d(TAG, "onReq: " + baseReq.getType());
		switch (baseReq.getType()) {
			case ConstantsAPI.COMMAND_GETMESSAGE_FROM_WX:
				break;
			case ConstantsAPI.COMMAND_SHOWMESSAGE_FROM_WX:
				goToShowMsg((ShowMessageFromWX.Req) baseReq);
				break;
			default:
				break;
		}

		finish();
	}

	private void goToShowMsg(ShowMessageFromWX.Req baseReq) {
	}

	@Override
	public void onResp(BaseResp resp) {
		Log.d(TAG, "onResp type:" + resp.getType());

		if (resp.getType() == ConstantsAPI.COMMAND_LAUNCH_WX_MINIPROGRAM) {
			WXLaunchMiniProgram.Resp launchMiniProResp = (WXLaunchMiniProgram.Resp) resp;
			// extraData为0000时支付成功，9999时支付失败
			String extraData = launchMiniProResp.extMsg;
			Log.d(TAG, "onReq extraData = " + extraData);
		}
		finish();
	}
}
	
