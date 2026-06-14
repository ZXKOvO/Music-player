#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include "player_controller.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // 注册播放控制器到 QML
    qmlRegisterType<PlayerController>("com.musicplayer.backend", 1, 0, "PlayerController");

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("MusicPlayer", "Main");

    return QGuiApplication::exec();
}
