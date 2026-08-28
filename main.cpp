#include <QApplication>
#include <QQmlApplicationEngine>
#include <QIcon>
#include <QNetworkProxyFactory>
#include <QQmlContext>
#include "src/playlist_manager.h"
#include "src/player_controller.h"
#include "src/playlist_model.h"
#include "src/lyrics_parser.h"
#include "src/song_searcher.h"
#include "src/search_result_model.h"
#include "src/net_image_provider.h"
int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    QCoreApplication::setOrganizationName("MusicPlayer");
    QCoreApplication::setApplicationName("MusicPlayer");
    QNetworkProxyFactory::setUseSystemConfiguration(false);
    app.setWindowIcon(QIcon(":/qt/qml/MusicPlayer/resources/icons/musicplayer_256.png"));

    QQmlApplicationEngine engine;
    NetImageProvider *netImgProvider = new NetImageProvider;
    engine.addImageProvider("net", netImgProvider);
    NetImageProvider::setInstance(netImgProvider);
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("MusicPlayer", "Main");

    return app.exec();
}
