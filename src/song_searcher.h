#pragma once
#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QString>
#include <QList>
#include <QtQml/qqmlregistration.h>
#include "search_result_model.h"

class SongSearcher : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(SearchResultModel *model READ model CONSTANT)
    Q_PROPERTY(bool searching READ searching NOTIFY searchingChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorMessageChanged)

public:
    explicit SongSearcher(QObject *parent = nullptr);

    SearchResultModel *model() const { return model_; }
    bool searching() const { return searching_; }
    QString errorMessage() const { return errorMessage_; }

    Q_INVOKABLE void search(const QString &keyword);
    Q_INVOKABLE void getSongUrl(int songId, const QString &songName, const QString &artist);

signals:
    void searchingChanged();
    void errorMessageChanged();
    void songUrlReady(const QString &filePath, const QString &songName, const QString &artist);
    void songUrlFailed(const QString &songName, const QString &reason);

private:
    QNetworkAccessManager *netMgr_;
    SearchResultModel *model_;
    bool searching_ = false;
    QString errorMessage_;
    int searchRequestId_ = 0;
};
