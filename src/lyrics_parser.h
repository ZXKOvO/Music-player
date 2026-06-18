#pragma once
#include <QObject>
#include <QVector>
#include <QPair>
#include <QString>
#include <QtQml/qqmlregistration.h>

// LRC 歌词解析器
class LyricsParser : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QString filePath READ filePath WRITE setFilePath NOTIFY filePathChanged)
    Q_PROPERTY(int lineCount READ lineCount NOTIFY lineCountChanged)
public:
    explicit LyricsParser(QObject *parent = nullptr);

    QString filePath() const { return filePath_; }
    void setFilePath(const QString &path);

    int lineCount() const { return lines_.size(); }

    // 解析 LRC 文件
    Q_INVOKABLE bool load(const QString &path);
    // 清空歌词
    Q_INVOKABLE void clear();

    // 根据当前播放时间获取歌词行索引（返回 -1 表示无歌词）
    Q_INVOKABLE int lineAt(double seconds) const;

    // 获取指定行的时间戳（秒）
    Q_INVOKABLE double timeAt(int index) const;
    // 获取指定行的歌词文本
    Q_INVOKABLE QString textAt(int index) const;

signals:
    void filePathChanged();
    void lineCountChanged();

private:
    // 从文件名推断同目录下的 .lrc 文件路径
    static QString guessLrcPath(const QString &audioPath);

    QString filePath_;
    QVector<QPair<double, QString>> lines_; // (时间戳秒, 歌词文本)
};
