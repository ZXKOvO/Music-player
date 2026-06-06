#include <QGuiApplication>
#include <QQmlApplicationEngine>
//#include <QFile>
//#include <QDebug>



int main(int argc, char *argv[])
{
//    qDebug() << QFile::exists(":/img/Resources/title/mini.png");
//    qDebug() << QFile::exists(":/img/Resources/title/close.png");
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;
    const QUrl url(QStringLiteral("qrc:/MusicPlayer/main.qml"));
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreated,
        &app,
        [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl) QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection);
    engine.load(url);

    return QGuiApplication::exec();
}
