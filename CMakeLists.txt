cmake_minimum_required(VERSION 3.16)
project(MusicPlayer VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)  # 生成 compile_commands.json，供 IDE 使用

find_package(Qt6 REQUIRED COMPONENTS Quick Network Qml)
find_package(PkgConfig REQUIRED)

qt_standard_project_setup(REQUIRES 6.9)

# 第三方依赖：FFmpeg（含 avfilter 用于 atempo 变速不变调）
pkg_check_modules(AV REQUIRED
    libavcodec
    libavformat
    libavutil
    libswresample
    libavfilter
)

# 第三方依赖：SDL2
pkg_check_modules(SDL2 REQUIRED sdl2)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
qt_add_executable(MusicPlayer  WIN32)
qt_add_qml_module(MusicPlayer
    URI MusicPlayer
    VERSION 1.0
    SOURCES
        main.cpp
        src/audio_decoder.h
        src/audio_decoder.cpp
        src/ring_buffer.h
        src/ring_buffer.cpp
        src/sdl_audio_output.h
        src/sdl_audio_output.cpp
        src/speed_switch.h
        src/speed_switch.cpp
        src/player_controller.h
        src/player_controller.cpp
        src/playlist_model.h
        src/playlist_model.cpp
        src/lyrics_parser.h
        src/lyrics_parser.cpp
        src/lyrics_fetcher.h
        src/lyrics_fetcher.cpp
        src/playlist_manager.h
        src/playlist_manager.cpp
        src/cover_image_provider.h
        src/cover_image_provider.cpp
        src/song_searcher.h
        src/song_searcher.cpp
        src/search_result_model.h
        src/search_result_model.cpp
    QML_FILES
        Main.qml
        qml/pages/PlaylistPage.qml
        qml/pages/PlaylistsPage.qml
        qml/pages/PlaylistDetailPage.qml
        qml/pages/LyricsPage.qml
        qml/pages/SearchPage.qml
        qml/components/ControlBar.qml
    RESOURCES
        resources/icons/add.svg
        resources/icons/shuffle.svg
        resources/icons/repeat.svg
        resources/icons/repeat-one.svg
        resources/icons/volume.svg
        resources/icons/volume-mute.svg
)

target_include_directories(MusicPlayer PRIVATE
    src/
    ${AV_INCLUDE_DIRS}
    ${SDL2_INCLUDE_DIRS}
)

target_link_libraries(MusicPlayer
    PRIVATE Qt6::Quick Qt6::Network Qt6::Qml
    ${AV_LIBRARIES}
    ${SDL2_LIBRARIES}
)

target_compile_options(MusicPlayer PRIVATE
    ${AV_CFLAGS_OTHER}
    ${SDL2_CFLAGS_OTHER}
)

# 定义项目源代码根目录，用于在线歌曲缓存路径
target_compile_definitions(MusicPlayer PRIVATE
    PROJECT_SOURCE_DIR="${CMAKE_SOURCE_DIR}"
)

set(CMAKE_INSTALL_PREFIX "/opt/${PROJECT_NAME}" CACHE PATH "Install path prefix" FORCE)
install(TARGETS MusicPlayer
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
