import 'package:coast_audio/coast_audio.dart';

import 'package:coast_audio/src/engine/engine/edit_playback_context.dart';
import 'package:music_core/src/time/time.dart';

class DeviceManager {
  static const int defaultNumChannelsToOpen = 2;
  final Engine engine;

  void initialise(int inputChannels, int outputChannels) {}

  final AudioFormat format = const AudioFormat(
      sampleRate: 48000, channels: 2, sampleFormat: SampleFormat.int16);

  final int bufferFrameSize = 1024;

  late final AudioDeviceBackend? backend;
  late final AudioDeviceId? inputDeviceId;
  late final AudioDeviceId? outputDeviceId;
  late final AudioDeviceContext context;
  late final CaptureDevice captureDevice;
  late final PlaybackDevice playbackDevice;
  late final AudioIntervalClock clock;
  late final AllocatedAudioFrames bufferFrames;

  Set<EditPlaybackContext> activeContexts = {};
  double streamTime = 0;

  double get inputStability =>
      captureDevice.availableWriteFrames / bufferFrameSize;
  double get outputStability =>
      playbackDevice.availableReadFrames / bufferFrameSize;
  AudioTime get latency => AudioTime.fromFrames(
      captureDevice.availableReadFrames + playbackDevice.availableReadFrames,
      format: format);

  DeviceManager(this.engine);

  Range<double> get globalStreamTime => Range(1, 1);

  double get currentSampleRate => 48000;

  initial({
    required AudioDeviceBackend backend,
    AudioDeviceId? inputDeviceId,
    AudioDeviceId? outputDeviceId,
  }) {
    // Initialize capture and playback nodes
    context = AudioDeviceContext(backends: [backend]);

    captureDevice = context.createCaptureDevice(
      format: format,
      bufferFrameSize: bufferFrameSize,
      deviceId: inputDeviceId,
    );

    playbackDevice = context.createPlaybackDevice(
      format: format,
      bufferFrameSize: bufferFrameSize,
      deviceId: outputDeviceId,
    );

    // Connect capture to playback
    // capture.outputBus.connect(playback.inputBus);

    // Initialize clock and buffer frames
    clock = AudioIntervalClock(const AudioTime(10 / 1000));
    bufferFrames =
        AllocatedAudioFrames(length: bufferFrameSize, format: format);
  }

  getCurrentAudioDevice() {}

  void addContext(EditPlaybackContext context) {
    double lastStreamTime = streamTime;
    context.resyncToGlobalStreamTime(
        Range(lastStreamTime,
            lastStreamTime + bufferFrameSize / currentSampleRate),
        currentSampleRate);
    activeContexts.add(context);
  }

  void prepareToStart() {}

  void audioDeviceIOCallbackWithContext(
    int numSamples,
  ) {}

  void start() {
    captureDevice.start();
    playbackDevice.start();
    clock.start(onTick: (_) {
      //bufferFrames.acquireBuffer((buffer) => playback.outputBus.read(buffer));
    });
  }

  void stop() {
    clock.stop();
    captureDevice.stop();
    playbackDevice.stop();
  }

  void audioDeviceIOCallbackInternal() {
    for (var context in activeContexts) {
      context.nextBlockStarted();
    }

    StatsResponse getStats() {
      final inputStability =
          captureDevice.availableWriteFrames / bufferFrameSize;
      final outputStability =
          playbackDevice.availableReadFrames / bufferFrameSize;
      final latency = AudioTime.fromFrames(
        captureDevice.availableReadFrames + playbackDevice.availableReadFrames,
        format: format,
      );
      return StatsResponse(
        inputStability: inputStability,
        outputStability: outputStability,
        latency: latency,
      );
    }
  }
}

class StatsResponse {
  const StatsResponse({
    required this.inputStability,
    required this.outputStability,
    required this.latency,
  });
  final double inputStability;
  final double outputStability;
  final AudioTime latency;
}
