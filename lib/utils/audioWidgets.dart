import 'dart:async';

import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';

import '../mainScreens/profile.dart';

class AudioRecorderWidget extends StatefulWidget {
  final void Function(String path, int recordDuration) onStop;

  const AudioRecorderWidget({
    Key? key,
    required this.onStop,
  }) : super(key: key);

  @override
  State<AudioRecorderWidget> createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends State<AudioRecorderWidget> {
  int _recordDuration = 0;
  Timer? _timer;
  final _audioRecorder = Record();
  StreamSubscription<RecordState>? _recordSub;
  RecordState _recordState = RecordState.stop;

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() => _recordDuration++);
    });
  }

  Future<void> _start() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        // We don't do anything with this but printing
        final isSupported = await _audioRecorder.isEncoderSupported(
          AudioEncoder.aacLc,
        );
        if (kDebugMode) {
          print('${AudioEncoder.aacLc.name} supported: $isSupported');
        }

        await _audioRecorder.start();
        _recordDuration = 0;

        _startTimer();
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Future<void> _stop() async {
    _timer?.cancel();
    _recordDuration = 0;

    final path = await _audioRecorder.stop();

    print(path);

    if (path != null) {
      widget.onStop(path, _recordDuration);
    }
  }

  Future<void> _pause() async {
    _timer?.cancel();
    await _audioRecorder.pause();
  }

  Future<void> _resume() async {
    _startTimer();
    await _audioRecorder.resume();
  }

  Widget _buildRecordStopControl() {
    late Icon icon;

    if (_recordState == RecordState.record) {
      icon = Icon(
        Icons.stop_rounded,
        color: color,
        size: MediaQuery.of(context).size.width * 0.1,
      );
    } else {
      icon = Icon(
        Icons.mic_rounded,
        color: color,
        size: MediaQuery.of(context).size.width * 0.1,
      );
    }

    return ClipOval(
      child: Material(
        color: color.withOpacity(0.3),
        child: GestureDetector(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.175,
            height: MediaQuery.of(context).size.width * 0.175,
            child: icon,
          ),
          onTap: () {
            if (_recordState == RecordState.pause) {
              _resume();
            } else if (_recordState == RecordState.record) {
              _stop();
            } else if (_recordState == RecordState.stop) {
              _start();
            }

            setState(() {});
          },
        ),
      ),
    );
  }

  Widget _buildPauseResumeControl() {
    return Visibility(
      visible: _recordState != RecordState.stop,
      maintainSize: true,
      maintainState: true,
      maintainAnimation: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.3,
          ),
          ClipOval(
            child: Material(
              color: color.withOpacity(0.3),
              child: GestureDetector(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.1,
                  height: MediaQuery.of(context).size.width * 0.1,
                  child: Icon(
                    Icons.pause_rounded,
                    color: color,
                    size: MediaQuery.of(context).size.width * 0.065,
                  ),
                ),
                onTap: () {
                  (_recordState == RecordState.pause) ? _resume() : _pause();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimer() {
    final String minutes = _formatNumber(_recordDuration ~/ 60);
    final String seconds = _formatNumber(_recordDuration % 60);

    return Text(
      '$minutes:$seconds',
      style: TextStyle(
        color: color,
        fontSize: 48,
      ),
    );
  }

  String _formatNumber(int number) {
    String numberStr = number.toString();
    if (number < 10) {
      numberStr = '0$numberStr';
    }

    return numberStr;
  }

  List<Amplitude> amplitudes = [];

  @override
  void initState() {
    _recordSub = _audioRecorder.onStateChanged().listen((recordState) {
      setState(() => _recordState = recordState);
    });

    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recordSub?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.width * 0.1,
        ),
        _buildTimer(),
        SizedBox(
          height: MediaQuery.of(context).size.width * 0.1,
        ),
        _buildRecordStopControl(),
        _buildPauseResumeControl(),
      ],
    );
  }
}

class AudioPlayer extends StatefulWidget {
  final int duration;

  /// Path from where to play recorded audio
  final String source;

  /// Callback when audio file should be removed
  /// Setting this to null hides the delete button
  final VoidCallback onDelete;

  const AudioPlayer({
    Key? key,
    required this.duration,
    required this.source,
    required this.onDelete,
  }) : super(key: key);

  @override
  AudioPlayerState createState() => AudioPlayerState();
}

class AudioPlayerState extends State<AudioPlayer> {
  final _audioPlayer = ap.AudioPlayer();
  late StreamSubscription<void> _playerStateChangedSubscription;
  late StreamSubscription<Duration?> _durationChangedSubscription;
  late StreamSubscription<Duration> _positionChangedSubscription;
  Duration? _position;
  Duration? _duration;

  String? error;

  Future<void> play() {
    return _audioPlayer.play(
      kIsWeb ? ap.UrlSource(widget.source) : ap.DeviceFileSource(widget.source),
    );
  }

  Future<void> resume() {
    _audioPlayer.seek(Duration(milliseconds: _position!.inMilliseconds));

    return _audioPlayer.play(
      kIsWeb ? ap.UrlSource(widget.source) : ap.DeviceFileSource(widget.source),
    );
  }

  Future<void> pause() => _audioPlayer.pause();

  Future<void> stop() {
    _audioPlayer.seek(Duration(milliseconds: _position!.inMilliseconds));

    _position = Duration.zero;

    return _audioPlayer.stop().then((value) => setState(() {}));
  }

  String _formatNumber(int number) {
    String numberStr = number.toString();
    if (number < 10) {
      numberStr = '0$numberStr';
    }

    return numberStr;
  }

  Widget _buildControl() {
    late Icon icon;

    if (_audioPlayer.state == ap.PlayerState.playing) {
      icon = Icon(
        Icons.stop_rounded,
        color: color,
        size: MediaQuery.of(context).size.width * 0.1,
      );
    } else {
      icon = Icon(
        Icons.play_arrow_rounded,
        color: color,
        size: MediaQuery.of(context).size.width * 0.1,
      );
    }

    return ClipOval(
      child: Material(
        color: color.withOpacity(0.3),
        child: GestureDetector(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.175,
            height: MediaQuery.of(context).size.width * 0.175,
            child: icon,
          ),
          onTap: () {
            if (_audioPlayer.state == ap.PlayerState.playing) {
              stop();
            } else if (_audioPlayer.state == ap.PlayerState.paused) {
              resume();
            } else if (_audioPlayer.state == ap.PlayerState.stopped) {
              play();
            }

            setState(() {});
          },
        ),
      ),
    );
  }

  Widget _buildPauseResumeControl() {
    return Visibility(
      visible: _audioPlayer.state != ap.PlayerState.stopped,
      maintainSize: true,
      maintainState: true,
      maintainAnimation: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.3,
          ),
          ClipOval(
            child: Material(
              color: color.withOpacity(0.3),
              child: GestureDetector(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.1,
                  height: MediaQuery.of(context).size.width * 0.1,
                  child: Icon(
                    Icons.pause_rounded,
                    color: color,
                    size: MediaQuery.of(context).size.width * 0.065,
                  ),
                ),
                onTap: () {
                  (_audioPlayer.state == ap.PlayerState.paused)
                      ? resume()
                      : pause();

                  setState(() {});
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider() {
    bool canSetValue = false;
    final duration = _duration;
    final position = _position;

    if (duration != null && position != null) {
      canSetValue = position.inMilliseconds > 0;
      canSetValue &= position.inMilliseconds < duration.inMilliseconds;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: Slider(
            activeColor: color,
            inactiveColor: color.withOpacity(0.3),
            onChanged: (v) {
              if (duration != null) {
                final position = v * duration.inMilliseconds;
                _audioPlayer.seek(Duration(milliseconds: position.round()));
              }
            },
            value: canSetValue && duration != null && position != null
                ? position.inMilliseconds / duration.inMilliseconds
                : 0.0,
          ),
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.7,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _position != null
                    ? '${_formatNumber(_position!.inMinutes ~/ 60)}:${_formatNumber(_position!.inSeconds % 60)}'
                    : '00:00',
              ),
              Text(
                '${_formatNumber(widget.duration ~/ 60)}:${_formatNumber(widget.duration % 60)}',
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    _playerStateChangedSubscription =
        _audioPlayer.onPlayerComplete.listen((state) async {
      await stop();
      setState(() {});
    });
    _positionChangedSubscription = _audioPlayer.onPositionChanged.listen(
      (position) => setState(() {
        _position = position;
      }),
    );
    _durationChangedSubscription = _audioPlayer.onDurationChanged.listen(
      (duration) => setState(() {
        _duration = duration;
      }),
    );

    _audioPlayer.getDuration();

    super.initState();
  }

  @override
  void dispose() {
    _playerStateChangedSubscription.cancel();
    _positionChangedSubscription.cancel();
    _durationChangedSubscription.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSlider(),
            _buildControl(),
            _buildPauseResumeControl(),
          ],
        );
      },
    );
  }
}

class WishAudioPlayer extends StatefulWidget {
  final bool isFile;
  final String source;

  const WishAudioPlayer({
    Key? key,
    required this.isFile,
    required this.source,
  }) : super(key: key);

  @override
  State<WishAudioPlayer> createState() => _WishAudioPlayerState();
}

class _WishAudioPlayerState extends State<WishAudioPlayer> {
  final _audioPlayer = ap.AudioPlayer();
  Duration maxDuration = Duration.zero;
  late StreamSubscription<void> _playerStateChangedSubscription;
  late StreamSubscription<Duration?> _durationChangedSubscription;
  late StreamSubscription<Duration> _positionChangedSubscription;
  Duration? _position;
  Duration? _duration;

  String? error;

  Future<void> play() {
    _position = Duration.zero;

    return _audioPlayer.play(
      widget.isFile
          ? ap.DeviceFileSource(widget.source)
          : ap.UrlSource(widget.source),
      position: _position,
    );
  }

  Future<void> resume() {
    _audioPlayer.seek(Duration(milliseconds: _position!.inMilliseconds));

    return _audioPlayer.play(
      ap.UrlSource(widget.source),
    );
  }

  Future<void> pause() => _audioPlayer.pause();

  Future<void> stop() {
    print('is stopped');

    _audioPlayer.seek(Duration(milliseconds: _position!.inMilliseconds));

    _position = const Duration(
      milliseconds: 0,
    );

    return _audioPlayer.stop().then((value) => setState(() {}));
  }

  String _formatNumber(int number) {
    String numberStr = number.toString();
    if (number < 10) {
      numberStr = '0$numberStr';
    }

    return numberStr;
  }

  Widget _buildControl() {
    late Icon icon;

    if (_audioPlayer.state == ap.PlayerState.paused ||
        _audioPlayer.state == ap.PlayerState.stopped) {
      icon = Icon(
        Icons.play_arrow_rounded,
        color: Colors.white,
        size: MediaQuery.of(context).size.width * 0.12,
      );
    } else {
      icon = Icon(
        Icons.pause_rounded,
        color: Colors.white,
        size: MediaQuery.of(context).size.width * 0.12,
      );
    }

    return GestureDetector(
      child: Container(
        color: Colors.transparent,
        height: MediaQuery.of(context).size.width * 0.12,
        width: MediaQuery.of(context).size.width * 0.12,
        child: Center(
          child: icon,
        ),
      ),
      onTap: () {
        if (_audioPlayer.state == ap.PlayerState.playing) {
          print('pause');

          pause();
        } else if (_audioPlayer.state == ap.PlayerState.paused) {
          print('resume');

          resume();
        } else if (_audioPlayer.state == ap.PlayerState.stopped) {
          print('play');

          play();
        } else {
          print('unknown player state');
        }

        setState(() {});
      },
    );
  }

  @override
  void initState() {
    _playerStateChangedSubscription =
        _audioPlayer.onPlayerComplete.listen((state) async {
      await stop();
      setState(() {});
    });

    _positionChangedSubscription = _audioPlayer.onPositionChanged.listen(
      (position) => setState(() {
        _position = position;
      }),
    );

    _durationChangedSubscription = _audioPlayer.onDurationChanged.listen(
      (duration) => setState(() {
        _duration = duration;
      }),
    );

    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      widget.isFile
          ? await _audioPlayer.setSourceDeviceFile(widget.source)
          : await _audioPlayer.setSourceUrl(widget.source);

      maxDuration = (await _audioPlayer.getDuration())!;

      print('max duration: ${maxDuration}');
    });
  }

  @override
  void dispose() {
    _playerStateChangedSubscription.cancel();
    _positionChangedSubscription.cancel();
    _durationChangedSubscription.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      margin: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.075,
      ),
      child: Row(
        children: [
          _buildControl(),
          Expanded(
            child: SizedBox(
              height: MediaQuery.of(context).size.width * 0.12,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.width * 0.06,
                      child: SliderTheme(
                        data: const SliderThemeData(
                          thumbShape: RoundSliderThumbShape(
                            enabledThumbRadius: 7,
                          ),
                        ),
                        child: Slider(
                          activeColor: Colors.white,
                          inactiveColor: Colors.white.withOpacity(0.3),
                          max: _duration?.inMilliseconds.toDouble() ?? 0,
                          onChanged: (value) async {
                            _position = Duration(milliseconds: value.toInt());

                            setState(() {});

                            await _audioPlayer.seek(
                              Duration(
                                milliseconds: value.toInt(),
                              ),
                            );
                          },
                          value: _position?.inMilliseconds.toDouble() ?? 0,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.05,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _position != null
                                ? '${_formatNumber(_position!.inMinutes ~/ 60)}:${_formatNumber(_position!.inSeconds % 60)}'
                                : '00:00',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${_formatNumber(maxDuration.inMinutes)}:${_formatNumber(maxDuration.inSeconds)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
