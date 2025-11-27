import 'dart:async';

import 'package:camera/camera.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:record/record.dart';

// late LiveModelSession _session;
// final _audioRecorder = YourAudioRecorder();
//

//
// // Initialize the Gemini Developer API backend service
// // Create a `LiveModel` instance with the flash-live model (only model that supports the Live API)
// final model = FirebaseAI.googleAI().liveGenerativeModel(
// model: 'gemini-2.0-flash-live-preview-04-09',
// // Configure the model to respond with audio
// liveGenerationConfig: LiveGenerationConfig(responseModalities: [ResponseModalities.audio]),
// );
//
// _session = await model.connect();
//
// final audioRecordStream = _audioRecorder.startRecordingStream();
// // Map the Uint8List stream to InlineDataPart stream
// final mediaChunkStream = audioRecordStream.map((data) {
// return InlineDataPart('audio/pcm', data);
// });
// await _session.startMediaStream(mediaChunkStream);
//
// // In a separate thread, receive the audio response from the model
// await for (final message in _session.receive()) {
// // Process the received message
// }

class GeminiLive extends StatefulWidget {
  const GeminiLive({super.key});

  @override
  State<GeminiLive> createState() => _GeminiLiveState();
}

class _GeminiLiveState extends State<GeminiLive> {
  //record
  final _recorder = AudioRecorder();
  late var audioStream;
  late var audioOutStream;
  final StreamController<Uint8List> _imageStreamController = StreamController();
  late CameraController _cameraController;
  var _captureTimer;
  late LiveGenerativeModel _liveModel;

  @override
  void initState() {
    super.initState();
    init();
  }


  init() async {
    recordInit();
    videoInit();
    speak();
  }

  recordInit() async {
    RecordConfig recordConfig = RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 16000,
      numChannels: 1,
      echoCancel: true,
      noiseSuppress: true,
    );

    final hasPermission = await _recorder.hasPermission();

    //start stream
    audioStream = await _recorder.startStream(recordConfig);
  }

  void videoInit() async {
    final cameras = await availableCameras();

    _cameraController = CameraController(
      cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      ),
      ResolutionPreset.veryHigh,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await _cameraController.initialize();

      _captureTimer = Timer.periodic(Duration(seconds: 1), (_) async {
        final XFile imageFile = await _cameraController.takePicture();
        Uint8List imageBytes = await imageFile.readAsBytes();
        _imageStreamController.add(imageBytes);
      });



    // _captureTimer?.cancel();
    // await _imageStreamController.close();
  }

  speak() async {
    await SoLoud.instance.init(sampleRate: 24000, channels: Channels.mono);

    audioOutStream = SoLoud.instance.setBufferStream(
      bufferingType: BufferingType.released,
      bufferingTimeNeeds: 0,
      format: BufferType.s16le,
    );
    // var handle = await SoLoud.instance.play(audioOutStream);
    // SoLoud.instance.addAudioDataStream(audioOutStream, audioChunk);
    // SoLoud.instance.setDataIsEnded(audioOutStream);
    // await SoLoud.instance.stop(handle);

    _liveModel = FirebaseAI.googleAI().liveGenerativeModel(
      model: 'gemini-2.0-flash-live-preview-04-09',
      liveGenerationConfig: LiveGenerationConfig(
        responseModalities: [ResponseModalities.audio],
        speechConfig: SpeechConfig(voiceName: 'fenrir'),
      ),
    );

    final LiveSession _liveSession = await _liveModel.connect();

    _liveSession.sendAudioRealtime(audioStream.map((data){
      return InlineDataPart('audio/pcm', data);
    }));

    _liveSession.sendMediaStream(_imageStreamController.stream.map((data){
      return InlineDataPart('audio/pcm', data);
    }));

    await for(final response in _liveSession.receive()){
      LiveServerMessage message  = response.message;
      if(message is LiveServerContent){
        for(final part in message.modelTurn!.parts){
            if(part is InlineDataPart && part.mimeType.startsWith('audio')){
              SoLoud.instance.addAudioDataStream(audioOutStream, part.bytes);
            }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Center(
                  child: _cameraController != null ? AspectRatio(
                    aspectRatio: _cameraController!.value.aspectRatio,
                    child: CameraPreview(_cameraController),
                  ) : SizedBox(),
                ),

              ],
            ),
          ),
        ],
      )
    );
  }

}