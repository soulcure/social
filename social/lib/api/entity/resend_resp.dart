class ResendResp {
  final String messageId;
  final int timestamp; //时间戳单位秒

  ResendResp({this.messageId, this.timestamp});

  Map<String, dynamic> toMap() {
    return {
      'message_id': messageId,
      'timestamp': timestamp,
    };
  }

  factory ResendResp.fromJson(Map<String, dynamic> map) {
    return ResendResp(
      messageId: map['message_id'] as String,
      timestamp: map['timestamp'] as int,
    );
  }
}
