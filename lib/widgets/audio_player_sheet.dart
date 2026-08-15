import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/poi_model.dart';
import '../services/api_service.dart';
import '../services/preferences_service.dart';

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

  final TextEditingController _questionController = TextEditingController();
  bool _isAsking = false;
  String? _aiAnswer;

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

    if (widget.poi.audioUrl != null && widget.poi.audioUrl!.isNotEmpty) {
      widget.audioPlayer.play(UrlSource(widget.poi.audioUrl!));
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _askAi() async {
    final q = _questionController.text.trim();
    if (q.isEmpty) return;

    setState(() => _isAsking = true);
    final voice = await PreferencesService.getSelectedVoice();

    try {
      final res = await ApiService.askGuide(
        poiId: widget.poi.id,
        question: q,
        voiceId: voice,
      );
      setState(() {
        _aiAnswer = res['answer'];
        _isAsking = false;
      });
      _questionController.clear();
    } catch (e) {
      setState(() => _isAsking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),

            Text(
              widget.poi.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              '${widget.poi.distanceMeters.toStringAsFixed(0)} м от вас',
              style: const TextStyle(color: Color(0xFFFF7675), fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),

            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFF6C5CE7),
                inactiveTrackColor: Colors.white12,
                thumbColor: const Color(0xFF6C5CE7),
              ),
              child: Slider(
                min: 0,
                max: _duration.inSeconds > 0 ? _duration.inSeconds.toDouble() : 1.0,
                value: _position.inSeconds.toDouble().clamp(0.0, _duration.inSeconds > 0 ? _duration.inSeconds.toDouble() : 1.0),
                onChanged: (v) => widget.audioPlayer.seek(Duration(seconds: v.toInt())),
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(_position), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text(_formatDuration(_duration), style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF6C5CE7),
                  child: IconButton(
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 32),
                    onPressed: () {
                      if (_isPlaying) {
                        widget.audioPlayer.pause();
                      } else {
                        widget.audioPlayer.resume();
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Divider(color: Colors.white10),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _questionController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '🎤 Спросить гида...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isAsking ? null : _askAi,
                  icon: _isAsking
                      ? const CircularProgressIndicator(color: Color(0xFF6C5CE7))
                      : const Icon(Icons.send, color: Color(0xFF6C5CE7)),
                )
              ],
            ),

            if (_aiAnswer != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                child: Text(_aiAnswer!, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              )
            ]
          ],
        ),
      ),
    );
  }
}
