//
//import 'package:audio_service/audio_service.dart';
//
//
////AudioService.connect();    // When UI becomes visible
////AudioService.start(        // When user clicks button to start playback
////backgroundTaskEntrypoint: myBackgroundTaskEntrypoint,
////androidNotificationChannelName: 'Music Player',
////androidNotificationIcon: "mipmap/ic_launcher",
////);
////AudioService.pause();      // When user clicks button to pause playback
////AudioService.play();       // When user clicks button to resume playback
////AudioService.disconnect();
//
//
//class BackgroundTaskHelper{
//
//  BackgroundAudioTask task;
//
//  void connect(){
//    AudioService.connect();
//  }
//
//  void disconnect(){
//    AudioService.disconnect();
//  }
//
//  void start(BackgroundAudioTask task){
//    AudioService.start(backgroundTaskEntrypoint: (){
//      AudioServiceBackground.run(() => task);
//    });
//  }
//}
//
//
//void taskEntryPoint() {
//  AudioServiceBackground.run(() => BackgroundTask());
//}
//
//
//class BackgroundTask extends BackgroundAudioTask {
//  @override
//  Future<void> onStart() async {
//    // Your custom dart code to start audio playback.
//    // NOTE: The background audio task will shut down
//    // as soon as this async function completes.
//  }
//
//  @override
//  void onStop() {
//    // Your custom dart code to stop audio playback.
//  }
//
//  @override
//  void onPlay() {
//    // Your custom dart code to resume audio playback.
//  }
//
//  @override
//  void onPause() {
//    // Your custom dart code to pause audio playback.
//  }
//
//  @override
//  void onClick(MediaButton button) {
//    // Your custom dart code to handle a media button click.
//  }
//}