# Music Player

基于 Qt6 + FFmpeg + SDL2 的音乐播放器。

## 功能

- 播放本地音频文件（mp3/flac/wav/aac/ogg/ape）
- 播放/暂停/切歌/进度跳转
- 音量调节、静音
- 变速播放（0.5x~2.0x）
- 播放模式：列表循环、单曲循环、随机播放
- 歌曲封面显示
- 歌词显示（LRC/YRC 格式，逐字高亮）
- 桌面歌词悬浮窗口
- 在线搜索和播放（网易云音乐）
- 歌单管理（新建/删除/增删歌曲）

## 依赖

- Qt 6.9+
- FFmpeg（libavcodec、libavformat、libavutil、libswresample、libavfilter）
- SDL2
- CMake 3.16+
- C++17

## 使用

1. 点击底部"+"按钮添加本地音频文件
2. 在搜索页搜索在线歌曲
3. 双击歌曲播放
4. 在"我的歌单"页管理歌单
5. 点击歌词按钮开启桌面歌词
