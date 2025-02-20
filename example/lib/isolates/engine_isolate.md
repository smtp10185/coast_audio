import 'dart:async';

import 'package:coast_audio/coast_audio.dart';
import 'package:coast_audio/experimental.dart';

enum EngineHostRequest {
  start,
  stop,
  stats,
}

class EngineStatsResponse {
  const EngineStatsResponse({
    required this.inputStability,
    required this.outputStability,
    required this.latency,
  });
  final double inputStability;
  final double outputStability;
  final AudioTime latency;
}

class _EngineMessage {
  const _EngineMessage({
    required this.backend,
    required this.inputDeviceId,
    required this.outputDeviceId,
  });
  final AudioDeviceBackend backend;
  final AudioDeviceId? inputDeviceId;
  final AudioDeviceId? outputDeviceId;
}

/// A DAW isolate that processes audio from a DAW engine and plays it back to an output device.
class EngineIsolate {
  EngineIsolate();

  final Edit edit = Edit.newEdit();

  final _isolate = AudioIsolate<_EngineMessage>(_worker);

  bool get isLaunched => _isolate.isLaunched;

  Future<void> launch({
    required AudioDeviceBackend backend,
    required AudioDeviceId? inputDeviceId,
    required AudioDeviceId? outputDeviceId,
  }) async {
    await _isolate.launch(
      initialMessage: _EngineMessage(
        backend: backend,
        inputDeviceId: inputDeviceId,
        outputDeviceId: outputDeviceId,
      ),
    );
  }

  Future<void> shutdown() {
    return _isolate.shutdown();
  }

  Future<void> start() {
    return _isolate.request(EngineHostRequest.start);
  }

  Future<void> stop() {
    return _isolate.request(EngineHostRequest.stop);
  }

  Future<EngineStatsResponse?> stats() {
    return _isolate.request(EngineHostRequest.stats);
  }

  /// The worker function that runs in the isolate.
  static Future<void> _worker(
      dynamic initialMessage, AudioIsolateWorkerMessenger messenger) async {
    AudioResourceManager.isDisposeLogEnabled = true;

    final message = initialMessage as _EngineMessage;

    // Connect the DAW engine to the playback node
    final engine = Engine(
        'demo'); // Assume DawEngine is a class that provides audio processing
    //engine.outputBus.connect(playback.inputBus)

    final DeviceManager deviceManager = engine.deviceManager;

    deviceManager.initial(
        backend: message.backend,
        inputDeviceId: message.inputDeviceId,
        outputDeviceId: message.outputDeviceId);

    messenger.listenRequest<EngineHostRequest>(
      (request) async {
        switch (request) {
          case EngineHostRequest.start:
            // 在每次播放前进行设置
            engine.setup();
          case EngineHostRequest.stop:
            engine.stop();
          case EngineHostRequest.stats:
            return EngineStatsResponse(
                inputStability: deviceManager.inputStability,
                outputStability: deviceManager.outputStability,
                latency: deviceManager.latency);
        }
      },
    );

    await messenger.listenShutdown(
      onShutdown: (reason, e, stackTrace) async {
        engine.stop();
      },
    );
  }
}
