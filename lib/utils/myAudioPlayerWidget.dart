import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class MyAudioPlayer extends StatefulWidget {
  final int audioDuration;
  final String source;
  const MyAudioPlayer({
    Key? key,
    required this.audioDuration,
    required this.source,
  }) : super(key: key);

  @override
  State<MyAudioPlayer> createState() => _MyAudioPlayerState();
}

class _MyAudioPlayerState extends State<MyAudioPlayer> {
  final player = AudioPlayer();

  bool loaded = false;
  bool loading = false;

  bool playing = false;

  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  double speed = 1;

  String formatNumber(int number) {
    String numberStr = number.toString();
    if (number < 10) {
      numberStr = '0$numberStr';
    }

    return numberStr;
  }

  Future setPlayer() async {
    player.setReleaseMode(ReleaseMode.stop);

    loading = true;

    setState(() {});

    await player.setSourceUrl(widget.source);

    loaded = true;
    loading = false;

    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    duration = Duration(seconds: widget.audioDuration);

    player.onPlayerStateChanged.listen(
      (state) {
        playing = state == PlayerState.playing;
      },
    );

    player.onPositionChanged.listen((newPosition) {
      setState(() {
        position = newPosition;
      });
    });
  }

  @override
  void dispose() {
    player.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.9,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.025,
              ),
              GestureDetector(
                onTap: () async {
                  if (playing) {
                    playing = false;

                    setState(() {});

                    await player.pause();
                  } else {
                    playing = true;

                    setState(() {});
                    if (loaded) {
                      await player.resume();
                    } else {
                      await setPlayer();
                      await player.resume();
                    }
                  }
                },
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.1,
                  child: Center(
                    child: loading
                        ? SizedBox(
                            width: MediaQuery.of(context).size.width * 0.05,
                            height: MediaQuery.of(context).size.width * 0.05,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth:
                                  MediaQuery.of(context).size.width * 0.01,
                            ),
                          )
                        : Icon(
                            playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: MediaQuery.of(context).size.width * 0.1,
                          ),
                  ),
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: const SliderThemeData(
                    thumbShape: RoundSliderThumbShape(
                      enabledThumbRadius: 7,
                    ),
                  ),
                  child: Slider(
                    max: duration.inMilliseconds.toDouble(),
                    inactiveColor: Colors.white.withOpacity(0.2),
                    activeColor: Colors.white.withOpacity(0.9),
                    thumbColor: Colors.white,
                    value: position.inMilliseconds.toDouble() <
                            duration.inMilliseconds.toDouble()
                        ? position.inMilliseconds.toDouble()
                        : duration.inMilliseconds.toDouble(),
                    onChanged: (value) async {
                      await player.seek(
                        Duration(
                          milliseconds: value.toInt(),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.19,
              ),
              Text(
                '${position.inMinutes % 60}:${formatNumber(position.inSeconds % 60)}',
                style: const TextStyle(
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black87,
                      blurRadius: 10,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(),
              ),
              Text(
                '${duration.inMinutes % 60}:${formatNumber(duration.inSeconds % 60)}',
                style: const TextStyle(
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black87,
                      blurRadius: 10,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.06,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
