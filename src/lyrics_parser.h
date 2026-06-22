#pragma once
#include <QObject>
#include <QVector>
#include <QPair>
#include <QString>
#include <QtQml/qqmlregistration.h>

// 单个字符的时间信息（用于逐字高亮）
struct CharInfo {
    double startSec;    // 该字符开始显示的时间（秒）
    double durationSec; // 该字符持续显示的时间（秒）
};

// 单行歌词的信息
struct LineInfo {
    double startSec;    // 行开始时间（秒）
    double durationSec; // 行持续时间（秒）
    QString text;       // 行内歌词文本
    QVector<CharInfo> charInfos; // 每个字符的时间信息（逐字模式下有值）
};

// 歌词解析器
// 支持两种格式：
//   1. YRC 逐字格式: [startMs,durationMs]字(startMs,durationMs)...
//   2. LRC 逐行格式: [mm:ss.xx]歌词文本
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

    Q_INVOKABLE bool load(const QString &path);
    Q_INVOKABLE bool loadFromString(const QString &lrcContent);
    Q_INVOKABLE void alignToDuration(double audioDuration);
    Q_INVOKABLE void clear();

    Q_INVOKABLE int lineAt(double seconds) const;
    Q_INVOKABLE double timeAt(int index) const;
    Q_INVOKABLE QString textAt(int index) const;

    // 根据播放时间获取当前应高亮的字符索引
    // 逐字模式：用真实时间戳匹配；逐行模式：等分时间
    Q_INVOKABLE int charIndexAt(double seconds, int lineIndex) const;

signals:
    void filePathChanged();
    void lineCountChanged();

private:
    static QString guessLrcPath(const QString &audioPath);
    // 解析 YRC 逐字歌词格式
    bool parseYrcContent(const QString &content);

    QString filePath_;
    QVector<LineInfo> lines_;
};
