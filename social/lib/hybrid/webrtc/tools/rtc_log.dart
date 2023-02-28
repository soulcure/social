import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/hybrid/webrtc/config.dart';
import 'package:im/themes/const.dart';

/// 日志列表组件
class RtcLog extends StatefulWidget {
  static final List<_Logs> _logs = [];

  static bool log(Object msg, [Object detail]) {
    if (debugRtc) {
      final msgStr = "${"[${DateTime.now().toString()}]"}$msg" ?? "";
      final detailStr = detail?.toString() ?? "";
      print("[RTC][log]$msgStr${detailStr == "" ? "" : ":$detailStr"}");
      _logs.add(_Logs(msgStr, detailStr, isMessage: false));
    }
    return true;
  }

  static bool message(Object msg, [Object detail]) {
    if (debugMessage) {
      final msgStr = msg?.toString() ?? "";
      final detailStr = detail?.toString() ?? "";
      print("[${DateTime.now().toString()}][RTC][message][$msgStr] $detailStr");
      _logs.add(_Logs(msgStr, detailStr));
    }
    return true;
  }

  @override
  _RtcLogState createState() => _RtcLogState();
}

class _RtcLogState extends State<RtcLog> {
  bool _showMessage = false;

  @override
  Widget build(BuildContext context) {
    if (RtcLog._logs.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text("WebRtc日志".tr),
          elevation: 0,
        ),
        body: Center(
          child: Text("还没有任何日志".tr),
        ),
      );
    }

    const divider = Divider(thickness: 0.5, height: 20, color: Colors.grey);
    const textStyle = TextStyle(fontSize: 16, color: Colors.blue);
    var logs = RtcLog._logs;
    if (!_showMessage) {
      logs = logs.where((item) {
        return item.isMessage == false;
      }).toList();
    }

    final len = logs.length;
    return Scaffold(
      appBar: AppBar(
        title: Text("WebRtc日志".tr),
        elevation: 0,
      ),
      body: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Checkbox(
                onChanged: (value) {
                  _showMessage = value;
                  setState(() {});
                },
                value: _showMessage,
              ),
              Text("是否显示通信消息".tr),
              spacer,
              TextButton(
                onPressed: () {
                  RtcLog._logs.length = 0;
                  setState(() {});
                },
                child: const Text("clear"),
              )
            ],
          ),
          Expanded(
            child: ListView.separated(
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final item = logs[index];
                return Container(
                  padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        "$index. ${item.msg}",
                        style: textStyle,
                      ),
                      if (item.detail != "") Text(item.detail)
                    ],
                  ),
                );
              },
              itemCount: len,
              separatorBuilder: (context, index) {
                return divider;
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Logs {
  final String msg;
  final bool isMessage;
  final String detail;

  const _Logs(this.msg, this.detail, {this.isMessage = true});
}
