import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:im/pages/home/home_page.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/avatar.dart';

import 'audio_player_manager.dart';

class PlayerBar extends StatefulWidget {
  @override
  _PlayerBarState createState() => _PlayerBarState();
}

class _PlayerBarState extends State<PlayerBar> with TickerProviderStateMixin {
  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(duration: const Duration(seconds: 20), vsync: this);
  }

  @override
  void dispose() {
    AudioPlayerManager.instance.audioPlayerState
        .removeListener(_onPlayStateChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AudioPlayerManager.instance.audioPlayerState
        .removeListener(_onPlayStateChanged);
    AudioPlayerManager.instance.audioPlayerState
        .addListener(_onPlayStateChanged);
    if (AudioPlayerManager.instance.channelId == null) {
      return const SizedBox();
    }
    final title = AudioPlayerManager.instance.title;
    final thumb = AudioPlayerManager.instance.thumb;
    if (AudioPlayerManager.instance.isPlaying)
      _controller?.repeat();
    else
      _controller?.stop();
    return SizedBox(
      width: 80,
      height: 102.5,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () async {
              await AudioPlayerManager.instance.stop();
              RestoreAudioPlayerViewNotification().dispatch(context);
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 4, 4, 0),
              child: Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(
                      Icons.power_settings_new,
                      color: Colors.white,
                      size: 10,
                    ),
                  )),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                GestureDetector(
                  onTap: () async {
                    switch (AudioPlayerManager.instance.playerState) {
                      case PlayerState.PAUSED:
                        await AudioPlayerManager.instance.resume();
                        break;
                      case PlayerState.PLAYING:
                        await AudioPlayerManager.instance.pause();
                        break;
                      case PlayerState.COMPLETED:
                      case PlayerState.STOPPED:
                        await AudioPlayerManager.instance.replay();
                        break;
                    }
                    setState(() {});
                  },
                  child: AudioPlayerManager.instance.isPlaying
                      ? RotationTransition(
                          turns: _controller,
                          child: Avatar(url: thumb, radius: 24),
                        )
                      : Stack(
                          alignment: Alignment.center,
                          children: [
                            RotationTransition(
                              turns: _controller,
                              child: Avatar(
                                url: thumb,
                                radius: 24,
                              ),
                            ),
                            Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(48))),
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
                sizeHeight8,
                const Divider(height: 0.5),
                sizeHeight8,
                SizedBox(
                  width: 70,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyText2
                        .copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onPlayStateChanged() {
    switch (AudioPlayerManager.instance.playerState) {
      case PlayerState.PAUSED:
        _controller?.stop();
        setState(() {});
        break;
      case PlayerState.PLAYING:
        _controller?.repeat();
        setState(() {});
        break;
      case PlayerState.STOPPED:
        _controller?.stop();
        RestoreAudioPlayerViewNotification().dispatch(context);
        break;
      case PlayerState.COMPLETED:
        _controller?.stop();
        setState(() {});
        break;
      default:
    }
  }
}
