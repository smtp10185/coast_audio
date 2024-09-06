import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:example/components/player_tile.dart';
import 'package:example/isolates/recorder_isolate.dart';
import 'package:example/models/audio_state.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class AudioGraphPage extends StatefulWidget {
  const AudioGraphPage({
    super.key,
    required this.audio,
  });
  final AudioStateConfigured audio;

  @override
  State<AudioGraphPage> createState() => _AudioGraphPageState();
}

class _AudioGraphPageState extends State<AudioGraphPage> {
  final files = <XFile>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Graph'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: ElevatedButton.icon(
                onPressed: () async {
                  final file = await openFile();
                  if (file != null) {
                    setState(() {
                      files.add(file);
                    });
                  }
                },
                icon: const Icon(Icons.file_open_rounded),
                label: const Text('Open File'),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (var i = 0; files.length > i; i++)
                    PlayerTile(
                      backend: widget.audio.backend,
                      outputDevice: widget.audio.outputDevice,
                      file: files[i],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
