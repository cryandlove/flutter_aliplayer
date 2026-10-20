import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_aliplayer/flutter_aliplayer.dart';

import 'video_item.dart';

class VideoDetailPage extends StatefulWidget {
  const VideoDetailPage({super.key, required this.video});

  final VideoItem video;

  @override
  State<VideoDetailPage> createState() => _VideoDetailPageState();
}

class _VideoDetailPageState extends State<VideoDetailPage>
    with WidgetsBindingObserver {
  late final FlutterAliplayer _player;
  late final Future<bool> _created;
  Timer? _positionTimer;
  bool _closed = false;
  bool _bound = false;
  bool _prepared = false;
  bool _playing = false;
  bool _completed = false;
  bool _dragging = false;
  bool _polling = false;
  bool _busy = false;
  bool _foreground = true;
  bool _startOnPrepared = true;
  int _generation = 0;
  String? _error;
  int _position = 0;
  int _duration = 0;

  bool get _active => mounted && !_closed;
  bool get _canControl => _prepared && _error == null && !_busy;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final AppLifecycleState? state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
    _startOnPrepared = _foreground;
    _player = FlutterAliplayer.init(null);
    _created = _createPlayer();
  }

  Future<bool> _createPlayer() async {
    try {
      await _player.create();
      if (!_active) {
        return true;
      }
      _player
        ..setOnPrepared(_onPrepared)
        ..setOnCompletion(_onCompletion)
        ..setOnError(_onError);
      return true;
    } catch (error) {
      _showError(error.toString());
      return false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground && _active) {
      _startOnPrepared = false;
      setState(() => _playing = false);
      unawaited(_pauseForBackground());
    }
  }

  Future<void> _pauseForBackground() async {
    try {
      if (await _created && _active) {
        await _player.pause();
      }
    } catch (error) {
      _showError(error.toString());
    }
  }

  void _close() {
    if (_closed) {
      return;
    }
    _closed = true;
    _generation++;
    _positionTimer?.cancel();
    unawaited(_releasePlayer());
  }

  Future<void> _releasePlayer() async {
    await _created;
    try {
      await _player.stop();
    } catch (error) {
      debugPrint('AliPlayer stop failed: $error');
    } finally {
      try {
        await _player.release();
      } catch (error) {
        debugPrint('AliPlayer release failed: $error');
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _close();
    super.dispose();
  }

  void _showError(String message) {
    if (!_active) {
      return;
    }
    _generation++;
    _positionTimer?.cancel();
    setState(() {
      _error = message;
      _prepared = false;
      _playing = false;
      _busy = false;
    });
  }

  void _onError(int code, String? extra, String? message, String playerId) {
    _showError('${message ?? '播放失败'} ($code)');
  }

  Future<void> _onPlayerViewCreated(int viewId) async {
    if (!await _created || !_active) {
      return;
    }
    try {
      await _player.setPlayerView(viewId);
      if (!_active) {
        return;
      }
      _bound = true;
      await _prepare();
    } catch (error) {
      _showError(error.toString());
    }
  }

  Future<void> _prepare() async {
    if (!_active || !_bound || _busy) {
      return;
    }
    final int generation = ++_generation;
    _positionTimer?.cancel();
    setState(() {
      _busy = true;
      _error = null;
      _prepared = false;
      _playing = false;
      _completed = false;
      _position = 0;
      _duration = 0;
      _startOnPrepared = _foreground;
    });
    try {
      await _player.setAutoPlay(false);
      if (!_active || generation != _generation) {
        return;
      }
      await _player.setUrl(widget.video.videoUrl);
      if (!_active || generation != _generation) {
        return;
      }
      await _player.prepare();
    } catch (error) {
      _showError(error.toString());
    } finally {
      if (_active && generation == _generation) {
        setState(() => _busy = false);
      }
    }
  }

  void _onPrepared(String playerId) {
    if (_active && _error == null) {
      unawaited(_finishPrepared(_generation));
    }
  }

  Future<void> _finishPrepared(int generation) async {
    try {
      final int duration = await _player.getDuration();
      if (!_active || generation != _generation) {
        return;
      }
      setState(() {
        _duration = duration > 0 ? duration : 0;
        _prepared = true;
      });
      _positionTimer?.cancel();
      _positionTimer = Timer.periodic(
          const Duration(milliseconds: 500), (_) => _readPosition());
      if (_startOnPrepared && _foreground) {
        await _player.play();
        if (!_active || generation != _generation) {
          return;
        }
        if (!_foreground || !_startOnPrepared) {
          await _player.pause();
          return;
        }
        setState(() => _playing = true);
      }
    } catch (error) {
      _showError(error.toString());
    }
  }

  Future<void> _readPosition() async {
    if (!_active || !_playing || _dragging || _polling) {
      return;
    }
    final int generation = _generation;
    _polling = true;
    try {
      final dynamic position = await _player.getCurrentPosition();
      if (_active && generation == _generation && !_dragging && !_completed &&
          position is int) {
        setState(() => _position = position.clamp(0, _duration));
      }
    } catch (error) {
      _showError(error.toString());
    } finally {
      _polling = false;
    }
  }

  void _onCompletion(String playerId) {
    if (_active) {
      setState(() {
        _position = _duration;
        _playing = false;
        _completed = true;
      });
    }
  }

  Future<void> _togglePlay() async {
    if (!_active || !_canControl || !_foreground) {
      return;
    }
    setState(() => _busy = true);
    try {
      if (_playing) {
        await _player.pause();
        if (_active) {
          setState(() => _playing = false);
        }
      } else {
        if (_completed) {
          await _player.seekTo(0, 0);
          if (!_active) {
            return;
          }
          setState(() {
            _position = 0;
            _completed = false;
          });
        }
        if (!_foreground) {
          return;
        }
        await _player.play();
        if (!_active) {
          return;
        }
        if (!_foreground) {
          await _player.pause();
          return;
        }
        setState(() => _playing = true);
      }
    } catch (error) {
      _showError(error.toString());
    } finally {
      if (_active) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _seek(double position) async {
    try {
      await _player.seekTo(position.toInt(), 0);
      if (_active) {
        setState(() {
          _position = position.toInt();
          _completed = false;
        });
      }
    } catch (error) {
      _showError(error.toString());
    } finally {
      _dragging = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      onPopInvokedWithResult: (bool didPop, _) {
        if (didPop) {
          _close();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('视频详情')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                children: <Widget>[
                  LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                      return AspectRatio(
                        aspectRatio: 16 / 9,
                        child: ColoredBox(
                          color: Colors.black,
                          child: Stack(
                            fit: StackFit.expand,
                            children: <Widget>[
                              AliPlayerView(
                                onCreated: _onPlayerViewCreated,
                                x: 0,
                                y: 0,
                                width: constraints.maxWidth,
                                height: constraints.maxWidth * 9 / 16,
                              ),
                              if (_error != null)
                                ColoredBox(
                                  color: Colors.black87,
                                  child: Center(
                                    child: SingleChildScrollView(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Text('播放失败：$_error',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  color: Colors.white)),
                                          const SizedBox(height: 8),
                                          TextButton.icon(
                                            onPressed: _bound ? _prepare : null,
                                            icon: const Icon(Icons.refresh),
                                            label: const Text('重试'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              else if (!_prepared)
                                const Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.white),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            IconButton(
                              tooltip: _playing ? '暂停' : (_completed ? '重播' : '播放'),
                              onPressed: _canControl ? _togglePlay : null,
                              icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
                            ),
                            Expanded(
                              child: Slider(
                                value: _position.clamp(0, _duration).toDouble(),
                                max: _duration > 0 ? _duration.toDouble() : 1,
                                onChanged: _canControl && _duration > 0
                                    ? (double value) =>
                                        setState(() => _position = value.toInt())
                                    : null,
                                onChangeStart: _canControl
                                    ? (_) => _dragging = true
                                    : null,
                                onChangeEnd: _canControl ? _seek : null,
                              ),
                            ),
                          ],
                        ),
                        Text('${_format(_position)} / ${_format(_duration)}',
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF65716C))),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(widget.video.title,
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            const Icon(Icons.account_circle_outlined,
                                color: Color(0xFF65716C)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(widget.video.author)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _format(int milliseconds) {
    final Duration duration = Duration(milliseconds: milliseconds);
    final String minutes = duration.inMinutes.toString().padLeft(2, '0');
    final String seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
