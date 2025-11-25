import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:dart_melty_soundfont/dart_melty_soundfont.dart';
import 'package:dart_melty_soundfont/soundfont.dart';
import 'package:mp_audio_stream/mp_audio_stream.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  // Linux/Desktop (Pure Dart)
  Synthesizer? _synthesizer;
  AudioStream? _audioStream;

  // Android/iOS (Native)
  final _midiPro = MidiPro();

  bool _isInitialized = false;

  // Buffer for audio generation (Linux only)
  static const int _sampleRate = 44100;
  static const int _bufferSize = 2048;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
        await _initializeDesktop();
      } else {
        await _initializeMobile();
      }
      _isInitialized = true;
      print("Audio Initialized");
    } catch (e) {
      print("Error initializing Audio: $e");
    }
  }

  Future<void> _initializeDesktop() async {
    // Load SoundFont
    ByteData byte = await rootBundle.load('assets/sounds/piano_font.sf2');
    final soundFont = SoundFont.fromByteData(byte);
    _synthesizer = Synthesizer.load(
      soundFont,
      SynthesizerSettings(sampleRate: _sampleRate),
    );

    // Initialize Audio Stream
    _audioStream = getAudioStream();
    _audioStream!.init(
      bufferMilliSec: 100,
      waitingBufferMilliSec: 20,
      channels: 2,
      sampleRate: _sampleRate,
    );

    // Push data periodically
    Timer.periodic(const Duration(milliseconds: 20), (timer) {
      if (_synthesizer != null && _audioStream != null) {
        _pushAudioData();
      }
    });
    print("Initialized Desktop Audio (Melty + MP Stream)");
  }

  Future<void> _initializeMobile() async {
    // Load SoundFont using loadSoundfontAsset which handles temp file internally
    // We need to provide the full asset path
    await _midiPro.loadSoundfontAsset(
      assetPath: 'assets/sounds/piano_font.sf2',
    );
    print("Initialized Mobile Audio (MidiPro)");
  }

  void _pushAudioData() {
    if (_synthesizer == null || _audioStream == null) return;

    final int frames = _bufferSize;
    final left = Float32List(frames);
    final right = Float32List(frames);

    _synthesizer!.render(left, right);

    // Interleave Left and Right into a single Float32List
    final interleaved = Float32List(frames * 2);
    for (int i = 0; i < frames; i++) {
      interleaved[i * 2] = left[i];
      interleaved[i * 2 + 1] = right[i];
    }

    // Push to stream
    _audioStream!.push(interleaved);
  }

  // Manual sustain tracking
  bool _sustainEnabled = false;
  final Set<int> _sustainedNotes = {};

  void playNote(int midiNote) {
    if (!_isInitialized) return;
    try {
      if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
        if (_synthesizer != null) {
          _synthesizer!.noteOn(channel: 0, key: midiNote, velocity: 100);
        }
      } else {
        _midiPro.playNote(channel: 0, key: midiNote, velocity: 100);
      }
    } catch (e) {
      print("Error playing note: $e");
    }
  }

  void stopNote(int midiNote) {
    if (!_isInitialized) return;

    // If sustain is enabled, don't stop the note yet, just track it
    if (_sustainEnabled) {
      _sustainedNotes.add(midiNote);
      return;
    }

    try {
      if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
        if (_synthesizer != null) {
          _synthesizer!.noteOff(channel: 0, key: midiNote);
        }
      } else {
        _midiPro.stopNote(channel: 0, key: midiNote);
      }
    } catch (e) {
      print("Error stopping note: $e");
    }
  }

  void setSustain(bool enabled) {
    _sustainEnabled = enabled;

    // If disabling sustain, stop all currently sustained notes
    if (!enabled) {
      for (final note in _sustainedNotes) {
        try {
          if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
            if (_synthesizer != null) {
              _synthesizer!.noteOff(channel: 0, key: note);
            }
          } else {
            _midiPro.stopNote(channel: 0, key: note);
          }
        } catch (e) {
          print("Error stopping sustained note: $e");
        }
      }
      _sustainedNotes.clear();

      // Also call stopAllNotes on mobile to be safe against lingering sounds
      if (Platform.isAndroid || Platform.isIOS) {
        _midiPro.stopAllNotes();
      }
    }
  }
}
