import 'package:im/core/config.dart';

const _rtcHosts = {
  Env.dev: "ws://rtc.tensafe.net:8188",
  Env.dev2: "wss://j1-dev2.fanbook.mobi:8989",
  Env.sandbox: "wss://j1-fat.fanbook.mobi:8989",
  Env.pre: "wss://j2.fanbook.mobi:8989",
  Env.pro: "wss://j1.fanbook.mobi:8989",
  Env.newtest: "wss://j1-newtest.fanbook.mobi:8989",
};

const _iceHosts = {
  Env.dev: "turn:rtc.tensafe.net:3478",
  Env.dev2: "turn:j1-dev2.fanbook.mobi:3478",
  Env.sandbox: "turn:j1-fat.fanbook.mobi:3478",
  Env.pre: "turn:j2.fanbook.mobi:3478",
  Env.pro: "turn:j1.fanbook.mobi:3478",
  Env.newtest: "turn:j1-newtest.fanbook.mobi:3478",
};

String get rtcHost {
  return _rtcHosts[Config.env];
  // return _rtcHosts[Env.test];
}

String get iceHost {
  return _iceHosts[Config.env];
  // return _iceHosts[Env.test];
}

const String iceUsername = 'test';
const String iceCredential = '123456';

const String audioPlugin = 'janus.plugin.audiobridge';
const String videoPlugin = 'janus.plugin.videoroom';
const String textPlugin = 'janus.plugin.textroom';
const String videocall = 'janus.plugin.videocall';

const bool debugMessage = true;
const bool debugRtc = true;
