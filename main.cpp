#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include "src/player_controller.h"
#include "src/playlist_model.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

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
