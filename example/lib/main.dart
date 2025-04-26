import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:coast_audio/coast_audio.dart';
import 'package:example/main_page.dart';
import 'package:example/models/audio_state.dart';
import 'package:example/pages/backend_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  AudioResourceManager.isDisposeLogEnabled = true;

  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid || Platform.isIOS) {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord));
    await session.setActive(true);
  }

  // 注册键盘事件拦截器，处理可能导致崩溃的键盘事件
  ServicesBinding.instance.keyboard.addHandler(_keyboardEventInterceptor);

  runApp(const ProviderScope(child: App()));
}

/// 键盘事件拦截器
/// 返回true表示事件已处理，不需要继续传递
/// 返回false表示需要继续传递事件
bool _keyboardEventInterceptor(KeyEvent event) {
  // 拦截可能导致问题的Meta/Windows键事件
  if (event.logicalKey == LogicalKeyboardKey.metaLeft ||
      event.logicalKey == LogicalKeyboardKey.metaRight) {
    // 拦截事件，防止它传递到Flutter的默认处理程序
    return true;
  }

  // 对于其他键，让Flutter继续正常处理
  return false;
}

class App extends StatefulWidget {
  const App({super.key});

  static AppState of(BuildContext context) {
    return context.findAncestorStateOfType<AppState>()!;
  }

  @override
  State<App> createState() => AppState();
}

class AppState extends State<App> {
  AudioState _state = const AudioStateInitial();

  AudioState get audioState => _state;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'coast_audio',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(
        useMaterial3: true,
      ),
      home: switch (_state) {
        AudioStateInitial() => const BackendPage(),
        AudioStateConfigured() =>
          MainPage(audio: _state as AudioStateConfigured),
      },
    );
  }

  void applyAudioState(AudioState state) {
    setState(() {
      _state = state;
    });
  }
}
