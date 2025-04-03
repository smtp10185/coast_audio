import 'package:coast_audio/coast_audio.dart';

class Engine {
  final String applicationName;
  late final DeviceManager deviceManager;
  final PropertyStorage propertyStorage;
  final UIBehaviour uiBehaviour;
  final EngineBehaviour engineBehaviour;
  final ProjectManager projectManager;
  final TemporaryFileManager temporaryFileManager;
  final AudioFileFormatManager audioFileFormatManager;
  final MidiProgramManager midiProgramManager;
  final ExternalControllerManager externalControllerManager;
  final BackgroundJobManager backgroundJobManager;
  final RenderManager renderManager;
  final AudioFileManager audioFileManager;
  final MidiLearnState midiLearnState;
  final PluginManager pluginManager;
  final EditDeleter editDeleter;
  final RecordingThumbnailManager recordingThumbnailManager;
  final WaveInputRecordingThread waveInputRecordingThread;
  final ActiveEdits activeEdits;

  GrooveTemplateManager? grooveTemplateManager;
  CompFactory? compFactory;
  WarpTimeFactory? warpTimeFactory;
  SharedTimer? backToArrangerUpdateTimer;
  BufferedAudioFileManager? bufferedAudioFileManager;

  // Prepare the audio clock with a tick interval of 10ms.
  static final clock = AudioIntervalClock(const AudioTime(10 / 1000));

  Engine(this.applicationName)
      : propertyStorage = PropertyStorage(applicationName),
        uiBehaviour = UIBehaviour(),
        engineBehaviour = EngineBehaviour(),
        projectManager = ProjectManager(),
        temporaryFileManager = TemporaryFileManager(),
        audioFileFormatManager = AudioFileFormatManager(),
        midiProgramManager = MidiProgramManager(),
        externalControllerManager = ExternalControllerManager(),
        backgroundJobManager = BackgroundJobManager(),
        renderManager = RenderManager(),
        audioFileManager = AudioFileManager(),
        midiLearnState = MidiLearnState(),
        pluginManager = PluginManager(),
        editDeleter = EditDeleter(),
        recordingThumbnailManager = RecordingThumbnailManager(),
        waveInputRecordingThread = WaveInputRecordingThread(),
        activeEdits = ActiveEdits() {
    deviceManager = DeviceManager(this);
    initialise();
  }

  void initialise() {
    // 初始化逻辑
    if (engineBehaviour.autoInitialiseDeviceManager()) {
      deviceManager.initialise(
          engineBehaviour.shouldOpenAudioInputByDefault()
              ? DeviceManager.defaultNumChannelsToOpen
              : 0,
          DeviceManager.defaultNumChannelsToOpen);
    }

    pluginManager.initialise();
    projectManager.initialise();
    externalControllerManager.initialise();
  }

  void setup() async {
    // Start the audio devices and the clock.
    deviceManager.captureDevice.start();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    deviceManager.playbackDevice.start();

    // Start the clock and process audio from the DAW engine every tick(10ms).
    clock.start(onTick: (_) {
      // Get new buffer from DAW engine
      //engine.process(bufferFrames);

      // Read from the capture device and write to the DAW engine
      deviceManager.bufferFrames.acquireBuffer((buffer) {
        deviceManager.captureDevice.read(buffer);
        //engine.inputBus.write(buffer);
      });

      // Write processed buffer to playback
      deviceManager.bufferFrames.acquireBuffer(
          (buffer) => deviceManager.playbackDevice.write(buffer));
    });
  }

  void stop() {
    clock.stop();
    deviceManager.stop();
  }

  static String getVersion() {
    return "Tracktion Engine v3.0.0";
  }

  GrooveTemplateManager getGrooveTemplateManager() {
    grooveTemplateManager ??= GrooveTemplateManager();
    return grooveTemplateManager!;
  }

  CompFactory getCompFactory() {
    compFactory ??= CompFactory();
    return compFactory!;
  }

  WarpTimeFactory getWarpTimeFactory() {
    warpTimeFactory ??= WarpTimeFactory();
    return warpTimeFactory!;
  }

  SharedTimer getBackToArrangerUpdateTimer() {
    backToArrangerUpdateTimer ??= SharedTimer(10);
    return backToArrangerUpdateTimer!;
  }

  BufferedAudioFileManager getBufferedAudioFileManager() {
    bufferedAudioFileManager ??= BufferedAudioFileManager();
    return bufferedAudioFileManager!;
  }
}

class PropertyStorage {
  final String applicationName;

  PropertyStorage(this.applicationName);
}

class UIBehaviour {
  // UI行为相关的实现
}

class EngineBehaviour {
  bool autoInitialiseDeviceManager() => true;
  bool shouldOpenAudioInputByDefault() => true;
}

class ProjectManager {
  void initialise() {
    // 初始化项目管理器
  }
}

class TemporaryFileManager {
  // 临时文件管理器相关的实现
}

class AudioFileFormatManager {
  // 音频文件格式管理器相关的实现
}

class MidiProgramManager {
  // MIDI程序管理器相关的实现
}

class ExternalControllerManager {
  void initialise() {
    // 初始化外部控制器管理器
  }
}

class BackgroundJobManager {
  // 后台作业管理器相关的实现
}

class RenderManager {
  // 渲染管理器相关的实现
}

class AudioFileManager {
  // 音频文件管理器相关的实现
}

class MidiLearnState {
  // MIDI学习状态相关的实现
}

class PluginManager {
  void initialise() {
    // 初始化插件管理器
  }
}

class EditDeleter {
  // 编辑删除器相关的实现
}

class RecordingThumbnailManager {
  // 录音缩略图管理器相关的实现
}

class WaveInputRecordingThread {
  // 波形输入录音线程相关的实现
}

class ActiveEdits {
  // 活动编辑相关的实现
}

class GrooveTemplateManager {
  // Groove模板管理器相关的实现
}

class CompFactory {
  // Comp工厂相关的实现
}

class WarpTimeFactory {
  // Warp时间工厂相关的实现
}

class SharedTimer {
  final int frequency;

  SharedTimer(this.frequency);
}

class BufferedAudioFileManager {
  // 缓冲音频文件管理器相关的实现
}
