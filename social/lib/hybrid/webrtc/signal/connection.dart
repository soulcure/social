import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:im/hybrid/webrtc/config.dart';
import 'package:im/hybrid/webrtc/tools/rtc_log.dart';

class Connection {
  bool _disposed = false;
  RTCPeerConnection _peerConn;
  Function(MediaStream) onAddStream;
  int handleId;

  /// 创建RTCPeerConnection
  Future<RTCPeerConnection> createPeer({
    Function(Map data) onIceCandidate,
    Function(String state, int handleId) onError,
    Function(int handleId) reconnectPeer,
    int handleId,
  }) async {
    this.handleId = handleId;
    _peerConn = await createPeerConnection(_configuration, _constraints);
    _peerConn.onIceCandidate = (candidate) {
      final data = candidate != null
          ? {
              "candidate": candidate.candidate,
              "sdpMid": candidate.sdpMid,
              "sdpMLineIndex": candidate.sdpMlineIndex
            }
          : const {"completed": true};
      onIceCandidate(data);
    };
    if (onAddStream != null) _peerConn.onAddStream = onAddStream;
    _peerConn.onIceConnectionState = (state) {
      RtcLog.message("onIceConnectionState $handleId, $state");
      if (state == RTCIceConnectionState.RTCIceConnectionStateDisconnected)
        onError?.call("failed", handleId);
      else if (state == RTCIceConnectionState.RTCIceConnectionStateClosed)
        onError?.call("closed", handleId);
    };

    _peerConn.onSelectedCandidatePairChanged = (pair) {
      final String reason = pair?.reason;
      if (reason?.contains('candidate pair state changed (after delay:') ??
          false) reconnectPeer?.call(handleId);
      RtcLog.message(
          'onSelectedCandidatePairChanged handleId:$handleId, $reason');
    };
    // _peerConn.onConnectionState =
    //     (state) => RtcLog.message("onConnectionState = $state");
    _peerConn.onRenegotiationNeeded =
        () => RtcLog.message("onRenegotiationNeeded = ");
    // _peerConn.onSignalingState =
    //     (state) => RtcLog.message("onSignalingState = $state");
    // _peerConn.onIceGatheringState =
    //     (state) => RtcLog.message("onIceGatheringState = $state");

    return _peerConn;
  }

  /// 添加本地流
  Future<void> addStream(MediaStream localStream) async {
    await _peerConn.addStream(localStream);
  }

  /// 主叫方创建 Offer
  Future<RTCSessionDescription> createOffer(Map constraints) async {
    // 设置本地媒体描述
    final RTCSessionDescription sdp = await _peerConn.createOffer(constraints);
    await _peerConn.setLocalDescription(sdp);
    return sdp;
  }

  Future<RTCSessionDescription> createOffer2(Map constraints) async =>
      _peerConn.createOffer(constraints);

  Future<void> restartIce() async {
    await _peerConn.restartIce();
  }

  /// 被呼叫方收到 Offer
  Future<RTCSessionDescription> receiveOffer(Map jsep) async {
    // 设置远端媒体描述
    final sdp = RTCSessionDescription(jsep['sdp'], jsep['type']);
    await _peerConn.setRemoteDescription(sdp);
    return sdp;
  }

  /// 被呼叫方创建应答
  Future<RTCSessionDescription> createAnswer(Map constraints) async {
    // 设置远端媒体描述
    final RTCSessionDescription sdp = await _peerConn.createAnswer(constraints);
    await _peerConn.setLocalDescription(sdp);
    return sdp;
  }

  Future<RTCSessionDescription> createAnswerSubs(Map constraints) async =>
      _peerConn.createAnswer(constraints);

  Future<void> setLocalDescription(RTCSessionDescription sdp) async =>
      _peerConn.setLocalDescription(sdp);

  /// 主叫方收到应答
  Future<RTCSessionDescription> receiveAnswer(Map jsep) async {
    return receiveOffer(jsep);
  }

  /// 获取 RTCRtpSender
  Future<RTCRtpSender> getVideoRtpSender() async {
    final List<RTCRtpSender> senders = await _peerConn.getSenders();
    return senders.firstWhere((sender) => sender.track.kind == 'video');
  }

  /// 创建DataChannel
  Future<RTCDataChannel> createDataChannel(String label) async {
    return _peerConn.createDataChannel(label, RTCDataChannelInit());
  }

  RTCIceConnectionState getConnectionStatus() => _peerConn.iceConnectionState;

  bool isRtcConnected() =>
      _peerConn.iceConnectionState ==
          RTCIceConnectionState.RTCIceConnectionStateConnected ||
      _peerConn.iceConnectionState ==
          RTCIceConnectionState.RTCIceConnectionStateCompleted;

  static const Map<String, dynamic> _constraints = {
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true}
    ],
  };

  static final Map<String, dynamic> _configuration = {
    'iceServers': [
      {
        'urls': iceHost,
        'url': iceHost,
        'username': iceUsername,
        'credential': iceCredential
      },
    ],
    'tcpCandidatePolicy': 'disabled',
    'continualGatheringPolicy': 'gather_once',
  };

  static const Map<String, dynamic> publicVideoConstraints = {
    'mandatory': {'OfferToReceiveAudio': false, 'OfferToReceiveVideo': false},
    'optional': [],
  };

  static const Map<String, dynamic> subscribeVideoConstraints = {
    'mandatory': {'OfferToReceiveAudio': true, 'OfferToReceiveVideo': true},
    'optional': [],
  };

  static const Map<String, dynamic> audioConstraints = {
    'mandatory': {'OfferToReceiveAudio': true, 'OfferToReceiveVideo': false},
    'optional': [],
  };

  static const Map<String, dynamic> restartAudioConstraints = {
    'mandatory': {'OfferToReceiveAudio': true, 'OfferToReceiveVideo': false},
    'optional': [
      {"iceRestart": true}
    ],
    "iceRestart": true,
  };

  static const Map<String, dynamic> textConstraints = {
    'mandatory': {'OfferToReceiveAudio': false, 'OfferToReceiveVideo': false},
    'optional': [],
  };

  ///获取 peerConn 的运行时状态信息
  Future<List<StatsReport>> getStats() async {
    try {
      if (!_disposed) {
        return await _peerConn.getStats();
      }
    } catch (_) {}
    return null;
  }

  /// 关闭
  Future<void> close() async {
    if (!_disposed) await _peerConn?.close();
  }

  /// 销毁
  Future<void> dispose() async {
    if (!_disposed) {
      _disposed = true;
      await _peerConn?.dispose();
    }
  }
}
