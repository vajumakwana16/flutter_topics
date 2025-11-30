import 'dart:async';
import 'dart:typed_data' show Uint8List;

import 'package:camera/camera.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:record/record.dart';
import 'package:firebase_core/firebase_core.dart';

class GeminiLive extends StatefulWidget {
  const GeminiLive({super.key});

  @override
  State<GeminiLive> createState() => _GeminiLiveState();
}

class _GeminiLiveState extends State<GeminiLive> {
  final _recorder = AudioRecorder();
  AudioSource? _audioOutStream;
  CameraController? _cameraController;
  Timer? _captureTimer;
  LiveGenerativeModel? _liveModel;
  late LiveSession _session;
  bool _isInitialized = false;
  bool _isListening = false;
  String _errorMessage = '';
  String _statusMessage = 'Initializing...';
  StreamSubscription<Uint8List>? _audioSubscription;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      setState(() => _statusMessage = 'Initializing camera...');
      await _initializeCamera();

      setState(() => _statusMessage = 'Initializing audio...');
      await _initializeAudio();

      setState(() => _statusMessage = 'Connecting to Gemini...');
      await _connectToGemini();

      setState(() {
        _isInitialized = true;
        _statusMessage = 'Ready! Tap to start';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Initialization error: $e';
        _statusMessage = 'Error occurred';
      });
      print('Error during initialization: $e');
    }
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw Exception('No cameras available');
    }

    _cameraController = CameraController(
      cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      ),
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await _cameraController!.initialize();
  }

  Future<void> _initializeAudio() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw Exception('Audio recording permission denied');
    }

    await SoLoud.instance.init(sampleRate: 24000, channels: Channels.mono);

    _audioOutStream = SoLoud.instance.setBufferStream(
      bufferingType: BufferingType.released,
      bufferingTimeNeeds: 0,
      format: BufferType.s16le,
    );
  }

  Future<void> _connectToGemini() async {
    // Initialize the Gemini Developer API backend service
    _liveModel = FirebaseAI.googleAI().liveGenerativeModel(
      // model: 'gemini-2.0-flash-live-preview-04-09',
      // model: 'gemini-2.0-flash-live-001',
      // model: 'gemini-live-2.5-flash',
      model: 'gemini-2.0-flash-exp',
      liveGenerationConfig: LiveGenerationConfig(
        responseModalities: [ResponseModalities.audio],
        speechConfig: SpeechConfig(voiceName: 'fenrir'),
      ),
    );

    _session = await _liveModel!.connect();
  }

  Future<void> _startStreaming() async {
    if (!_isInitialized || _isListening) return;

    setState(() {
      _isListening = true;
      _statusMessage = 'Listening...';
    });

    try {
      // Start audio recording stream
      final recordConfig = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
        echoCancel: true,
        noiseSuppress: true,
      );

      final audioStream = await _recorder.startStream(recordConfig);

      // Listen to audio stream and send each chunk
      _audioSubscription = audioStream.listen((audioData) {
        try {
          _session.sendAudioRealtime(InlineDataPart('audio/pcm', audioData));
        } catch (e) {
          print('Error sending audio chunk: $e');
        }
      });

      // Start camera capture for video frames
      _captureTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
        await _captureAndSendFrame();
      });

      // Listen for responses
      _listenForResponses();
    } catch (e) {
      print('Error starting stream: $e');
      setState(() {
        _errorMessage = 'Streaming error: $e';
        _isListening = false;
        _statusMessage = 'Error occurred';
      });
    }
  }

  Future<void> _captureAndSendFrame() async {
    try {
      if (_cameraController != null &&
          _cameraController!.value.isInitialized &&
          _isListening) {
        final XFile imageFile = await _cameraController!.takePicture();
        final Uint8List imageBytes = await imageFile.readAsBytes();

        // Send the image using sendRealtimeInput
        _session.sendVideoRealtime(InlineDataPart('image/jpeg', imageBytes));
      }
    } catch (e) {
      print('Error capturing/sending frame: $e');
    }
  }

  void _listenForResponses() async {
    try {
      await for (final response in _session!.receive()) {
        final message = response.message;

        if (message is LiveServerContent) {
          if (message.modelTurn?.parts != null) {
            for (final part in message.modelTurn!.parts) {
              if (part is InlineDataPart && part.mimeType.startsWith('audio')) {
                if (_audioOutStream != null && _isListening) {
                  SoLoud.instance.addAudioDataStream(_audioOutStream!, part.bytes);
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error receiving responses: $e');
    }
  }

  Future<void> _stopStreaming() async {
    if (!_isListening) return;

    setState(() {
      _isListening = false;
      _statusMessage = 'Stopped';
    });

    _captureTimer?.cancel();
    await _recorder.stop();
    _audioSubscription?.cancel();
  }

  @override
  void dispose() {
    _captureTimer?.cancel();
    _audioSubscription?.cancel();
    _recorder.dispose();
    _cameraController?.dispose();
    SoLoud.instance.deinit();
    _session?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Status bar
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black87,
              child: Row(
                children: [
                  Icon(
                    _isListening ? Icons.mic : Icons.mic_off,
                    color: _isListening ? Colors.red : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Camera preview
            Expanded(
              child: Stack(
                children: [
                  if (_cameraController != null &&
                      _cameraController!.value.isInitialized)
                    Center(
                      child: AspectRatio(
                        aspectRatio: _cameraController!.value.aspectRatio,
                        child: CameraPreview(_cameraController!),
                      ),
                    )
                  else if (_errorMessage.isNotEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),

                  // Listening indicator
                  if (_isListening)
                    Positioned(
                      top: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, color: Colors.white, size: 12),
                            SizedBox(width: 8),
                            Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Control buttons
            Container(
              padding: const EdgeInsets.all(24),
              color: Colors.black87,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Start button
                  ElevatedButton.icon(
                    onPressed: _isInitialized && !_isListening
                        ? _startStreaming
                        : null,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      disabledBackgroundColor: Colors.grey,
                    ),
                  ),

                  // Stop button
                  ElevatedButton.icon(
                    onPressed: _isListening ? _stopStreaming : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      disabledBackgroundColor: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}