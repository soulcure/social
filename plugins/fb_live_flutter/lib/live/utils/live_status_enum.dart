enum LiveStatus {
  none,
  openLiveSuccess, //开播成功
  openLiveFailed, //开播失败
  anchorClosesLive, //主播关闭直播
  anchorViolation, //主播违规关闭直播
  anchorLeave, //主播离开
  playStreamSuccess, //拉流成功
  networkError, //网络问题，无法开启直播 //网络连接不稳定 //网络不稳定 //网络错误
  abnormalLogin, //账号异地登录
  pushStreamFailed, //推流失败
  pushStreamSuccess, //推流成功
  playStreamFailed, //拉流失败
  kickOutServer, //踢出服务器
}
