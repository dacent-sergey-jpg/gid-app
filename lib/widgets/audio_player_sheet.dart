import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/api_service.dart';

class AudioPlayerSheet extends StatefulWidget {
  final PoiModel poi;
  final AudioPlayer audioPlayer;

  const AudioPlayerSheet({
    super.key,
    required this.poi,
    required this.audioPlayer,
  });

  @override
  State<AudioPlayerSheet> createState() => _AudioPlayerSheetState();
}

class _AudioPlayerSheetState extends State<AudioPlayerSheet> {
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;
  double _playbackRate = 1.0;

  @override
  void initState() {
    super.initState();

    widget.audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });

    widget.audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });

    widget.audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _changeSpeed() {
    final speeds = [1.0, 1.25, 1.5, 2.0];
    final currentIndex = speeds.indexOf(_playbackRate);
    final nextRate = speeds[(currentIndex + 1) % speeds.length];
    
    widget.audioPlayer.setPlaybackRate(nextRate);
    setState(() => _playbackRate = nextRate);
  }

  void _seekRelative(int seconds) {
    final target = _position + Duration(seconds: seconds);
    if (target < Duration.zero) {
      widget.audioPlayer.seek(Duration.zero);
    } else if (target > _duration) {
      widget.audioPlayer.seek(_duration);
    } else {
      widget.audioPlayer.seek(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      bottom: true,
      child: Container(
        padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + bottomPadding),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              widget.poi.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.poi.distanceMeters.toStringAsFixed(0)} м от вас',
              style: const TextStyle(color: Color(0xFFFF9800), fontSize: 13),
            ),
            const SizedBox(height: 16),

            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFFFF5722),
                inactiveTrackColor: Colors.white12,
                thumbColor: const Color(0xFFFF5722),
                trackHeight: 4,
              ),
              child: Slider(
                min: 0,
                max: _duration.inSeconds > 0 ? _duration.inSeconds.toDouble() : 1.0,
                value: _position.inSeconds.toDouble().clamp(
                  0.0,
                  _duration.inSeconds > 0 ? _duration.inSeconds.toDouble() : 1.0,
                ),
                onChanged: (value) {
                  widget.audioPlayer.seek(Duration(seconds: value.toInt()));
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(_position), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(_formatDuration(_duration), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: _changeSpeed,
                  child: Text(
                    '${_playbackRate}x',
                    style: const TextStyle(color: Color(0xFFFF5722), fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                IconButton(
                  iconSize: 32,
                  icon: const Icon(Icons.replay_10, color: Colors.white),
                  onPressed: () => _seekRelative(-10),
                ),
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFFF5722),
                  child: IconButton(
                    iconSize: 32,
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                    onPressed: () {
                      if (_isPlaying) {
                        widget.audioPlayer.pause();
                      } else {
                        widget.audioPlayer.resume();
                      }
                    },
                  ),
                ),
                IconButton(
                  iconSize: 32,
                  icon: const Icon(Icons.forward_10, color: Colors.white),
                  onPressed: () => _seekRelative(10),
                ),
                const SizedBox(width: 32),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
