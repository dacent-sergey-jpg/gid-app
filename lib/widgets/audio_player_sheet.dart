import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/poi_model.dart';

class AudioPlayerSheet extends StatefulWidget {
  final PoiModel poi;

  const AudioPlayerSheet({
    super.key,
    required this.poi,
  });

  @override
  State<AudioPlayerSheet> createState() => _AudioPlayerSheetState();
}

class _AudioPlayerSheetState extends State<AudioPlayerSheet> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() {
          _duration = newDuration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() {
          _position = newPosition;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      if (widget.poi.audioUrl != null && widget.poi.audioUrl!.isNotEmpty) {
        await _audioPlayer.play(UrlSource(widget.poi.audioUrl!));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.poi.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (widget.poi.distance != null)
            Text(
              'Расстояние: ${widget.poi.distance!.toStringAsFixed(0)} м',
              style: const TextStyle(color: Colors.grey),
            ),
          const SizedBox(height: 16),
          Slider(
            min: 0,
            max: _duration.inSeconds.toDouble(),
            value: _position.inSeconds.toDouble().clamp(0, _duration.inSeconds.toDouble()),
            onChanged: (value) async {
              final position = Duration(seconds: value.toInt());
              await _audioPlayer.seek(position);
            },
          ),
          IconButton(
            iconSize: 48,
            icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle),
            onPressed: _togglePlayPause,
          ),
        ],
      ),
    );
  }
}
