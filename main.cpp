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
    qmlRegisterType<PlaylistManager>("MusicPlayer", 1, 0, "PlaylistManager");
    qmlRegisterType<PlayerController>("MusicPlayer", 1, 0, "PlayerController");
    qmlRegisterType<PlaylistModel>("MusicPlayer", 1, 0, "PlaylistModel");
    qmlRegisterType<LyricsParser>("MusicPlayer", 1, 0, "LyricsParser");
    qmlRegisterType<SongSearcher>("MusicPlayer", 1, 0, "SongSearcher");
    qmlRegisterType<SearchResultModel>("MusicPlayer", 1, 0, "SearchResultModel");
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
