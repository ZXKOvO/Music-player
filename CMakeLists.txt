cmake_minimum_required(VERSION 3.16)

project(MusicPlayer VERSION 0.1 LANGUAGES CXX)

set(CMAKE_AUTOMOC ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.2 REQUIRED COMPONENTS Quick Core Gui)

qt_add_executable(appMusicPlayer
    main.cpp
)

qt_add_qml_module(
    appMusicPlayer
    URI MusicPlayer
    VERSION 1.0
    QML_FILES
        main.qml
        QML_FILES Src/leftPage/LeftPage.qml
        QML_FILES Src/rightPage/RightPage.qml
        QML_FILES Src/playMusic/PlayMusic.qml
        QML_FILES Src/title/MinAndMax.qml

)
qt_add_resources(appMusicPlayer resources
    PREFIX "/img"
    FILES
        Resources/title/mini.png
        Resources/title/close.png
        Resources/title/logo.png
        Resources/title/search.png
        Resources/title/user.png
        Resources/title/arrow.png
        Resources/title/message.png
        Resources/title/setting.png
        Resources/title/skin.png
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appMusicPlayer PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appMusicPlayer
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appMusicPlayer
    PRIVATE Qt6::Quick Qt6::Core Qt6::Gui
)

include(GNUInstallDirs)
install(TARGETS appMusicPlayer
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR})
