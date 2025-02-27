import 'dart:io';

import 'package:coast_audio/coast_audio.dart';
import 'package:example/main.dart';
import 'package:example/models/audio_state.dart';
import 'package:flutter/material.dart';

class BackendPage extends StatefulWidget {
  const BackendPage({super.key});

  @override
  State<BackendPage> createState() => _BackendPageState();
}

class _BackendPageState extends State<BackendPage> {
  final backends = <AudioDeviceBackend, bool>{};

  @override
  void initState() {
    super.initState();
    for (final backend in AudioDeviceBackend.values) {
      backends[backend] = switch (backend) {
        AudioDeviceBackend.coreAudio => Platform.isMacOS || Platform.isIOS,
        AudioDeviceBackend.aaudio => Platform.isAndroid,
        AudioDeviceBackend.openSLES => Platform.isAndroid,
        AudioDeviceBackend.wasapi => Platform.isWindows,
        AudioDeviceBackend.alsa => Platform.isLinux,
        AudioDeviceBackend.pulseAudio => Platform.isLinux,
        AudioDeviceBackend.jack => Platform.isLinux,
        AudioDeviceBackend.dummy => true,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Backend'),
      ),
      body: ListView.builder(
        itemCount: AudioDeviceBackend.values.length,
        itemBuilder: (context, index) {
          final backend = AudioDeviceBackend.values[index];
          return CheckboxListTile.adaptive(
            value: backends[backend],
            title: Text(
              switch (backend) {
                AudioDeviceBackend.coreAudio => 'Core Audio',
                AudioDeviceBackend.aaudio => 'AAudio',
                AudioDeviceBackend.openSLES => 'OpenSL ES',
                AudioDeviceBackend.wasapi => 'WASAPI',
                AudioDeviceBackend.alsa => 'ALSA',
                AudioDeviceBackend.pulseAudio => 'PulseAudio',
                AudioDeviceBackend.jack => 'JACK',
                AudioDeviceBackend.dummy => 'Dummy',
              },
            ),
            subtitle: Text(
              switch (backend) {
                AudioDeviceBackend.coreAudio => 'macOS, iOS',
                AudioDeviceBackend.aaudio => 'Android 8+',
                AudioDeviceBackend.openSLES => 'Android 4.1+',
                AudioDeviceBackend.wasapi => 'Windows Vista+',
                AudioDeviceBackend.alsa => 'Linux',
                AudioDeviceBackend.pulseAudio => 'Linux',
                AudioDeviceBackend.jack => 'Linux',
                AudioDeviceBackend.dummy => 'All platforms',
              },
            ),
            onChanged: (isChecked) {
              setState(() {
                backends[backend] = isChecked!;
              });
            },
          );
        },
      ),
      // Breakpoint here: This is where the FloatingActionButton click handler starts
      // This will be triggered when the user clicks the check button and at least one backend is selected
      floatingActionButton: FloatingActionButton(
        onPressed: !backends.values.any((v) => v)
            ? null
            : () async {
                AudioDeviceContext deviceContext;

                try {
                  var selectedBackends = backends.entries
                      .where((e) => e.value)
                      .map((e) => e.key)
                      .toList();

                  deviceContext = AudioDeviceContext(
                    backends: selectedBackends,
                  );
                } on MaException catch (e) {
                  if (e.result == MaResult.noBackend) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Could not activate any of the selected backends.'),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                  return;
                }

                var backendName = switch (deviceContext.activeBackend) {
                  AudioDeviceBackend.coreAudio => 'Core Audio',
                  AudioDeviceBackend.aaudio => 'AAudio',
                  AudioDeviceBackend.openSLES => 'OpenSL ES',
                  AudioDeviceBackend.wasapi => 'WASAPI',
                  AudioDeviceBackend.alsa => 'ALSA',
                  AudioDeviceBackend.pulseAudio => 'PulseAudio',
                  AudioDeviceBackend.jack => 'JACK',
                  AudioDeviceBackend.dummy => 'Dummy',
                };

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('\'$backendName\' activated.'),
                  ),
                );

                var defaultInputDevice = deviceContext
                    .getDevices(AudioDeviceType.capture)
                    .where((d) => d.isDefault)
                    .firstOrNull;

                var defaultOutputDevice = deviceContext
                    .getDevices(AudioDeviceType.playback)
                    .where((d) => d.isDefault)
                    .firstOrNull;

                App.of(context).applyAudioState(
                  AudioStateConfigured(
                    backend: deviceContext.activeBackend,
                    inputDevice: defaultInputDevice,
                    outputDevice: defaultOutputDevice,
                  ),
                );
              },
        child: const Icon(Icons.check),
      ),
    );
  }
}
