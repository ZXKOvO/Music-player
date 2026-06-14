cmake_minimum_required(VERSION 3.16)
project(MusicPlayer VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Quick)
find_package(PkgConfig REQUIRED)

qt_standard_project_setup(REQUIRES 6.9)

# 第三方依赖：FFmpeg
pkg_check_modules(AV REQUIRED
    libavcodec
    libavformat
    libavutil
    libswresample
)

# 第三方依赖：SDL2
pkg_check_modules(SDL2 REQUIRED sdl2)

qt_add_executable(appMusicPlayer  WIN32)
qt_add_qml_module(appMusicPlayer
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
        src/player_controller.h
        src/player_controller.cpp
    QML_FILES
        Main.qml
)

target_include_directories(appMusicPlayer PRIVATE
    src/
    ${AV_INCLUDE_DIRS}
    ${SDL2_INCLUDE_DIRS}
)

target_link_libraries(appMusicPlayer
    PRIVATE Qt6::Quick
    ${AV_LIBRARIES}
    ${SDL2_LIBRARIES}
)

target_compile_options(appMusicPlayer PRIVATE
    ${AV_CFLAGS_OTHER}
    ${SDL2_CFLAGS_OTHER}
)

set(CMAKE_INSTALL_PREFIX "/opt/${PROJECT_NAME}" CACHE PATH "Install path prefix" FORCE)
install(TARGETS appMusicPlayer
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
