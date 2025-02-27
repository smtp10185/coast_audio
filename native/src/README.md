# Coast Audio封装说明

本文件描述了以 ca_ 前缀命名的各模块对 miniaudio 的封装及扩展，帮助上层应用更便捷的使用音频功能。

## 1. ca_context

- 负责初始化、获取和销毁 miniaudio 的上下文（ma_context）。
- 函数包括：
  - ca_context_init：分配并调用 miniaudio 的 ma_context_init 来创建音频上下文。
  - ca_context_get_ref：获取内部的 ma_context 指针，用于后续调用 miniaudio API。
  - ca_context_uninit：清理上下文资源，包括调用 ma_context_uninit 和释放内存。

## 2. ca_dart

- 用于与 Dart 层进行交互，通常在 Flutter 或 Dart FFI 环境下使用。
- 提供接口将 C 层的音频操作封装，以便 Dart 层调用。
- 具体实现可能涉及数据类型转换、回调函数封装等，以适应 Dart 的调用约定。

## 3. ca_device

- 封装了 miniaudio 的设备管理功能。
- 提供设备的枚举、打开/关闭、启动捕获或播放等功能。
- 使上层用户可以通过简化的接口直接进行音频设备的操作，无需直接与底层复杂的设备操作打交道。

## 4. ca_log

- 封装了 miniaudio 日志系统，对日志回调进行适配。
- 提供日志回调函数，允许用户设置自定义日志输出行为。
- 在内部与 miniaudio 的日志机制对接，便于调试和日志管理。

## 5. coast_audio 和 dart_types

- coast_audio.c 和 coast_audio.h 主要作为对外暴露的接口文件，将所有 ca_ 系列封装整合到一起，形成一个整体的音频库。
- dart_types.h 定义了在与 Dart 层交互时涉及的跨语言数据类型，确保类型的一致性和正确性。

## 6. 其他辅助模块

- SymbolKeeper.swift：用于防止在链接时被剔除的符号，确保所有需要导出的符号能够保留，可供 Dart FFI 调用时正常加载。

## 总结

该封装层主要对 miniaudio 的核心功能进行简单化处理，将初始化、设备管理和日志等功能以 ca_ 前缀的接口进行封装，另外还提供了与 Dart 层交互的桥梁，方便在 Flutter 或其他 Dart 平台上使用。从而减少上层使用者对 miniaudio 复杂细节的直接依赖，提高开发效率。
