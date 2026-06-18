#include "lyrics_parser.h"
#include <QFile>
#include <QTextStream>
#include <QRegularExpression>
#include <QFileInfo>
#include <QDebug>

LyricsParser::LyricsParser(QObject *parent)
    : QObject(parent)
{
}

void LyricsParser::setFilePath(const QString &path)
{
    filePath_ = path;
    emit filePathChanged();

    // 尝试加载对应的歌词文件
    QString lrcPath = guessLrcPath(path);
    qDebug() << "LyricsParser: looking for LRC file:" << lrcPath;
    if (!lrcPath.isEmpty()) {
        load(lrcPath);
    } else {
        qDebug() << "LyricsParser: no LRC file found for:" << path;
        clear();
    }
}

bool LyricsParser::load(const QString &path)
{
    clear();

    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qWarning() << "Cannot open lyrics file:" << path;
        return false;
    }

    // 尝试自动检测编码
    QTextStream ts(&file);
    ts.setEncoding(QStringConverter::Utf8);
    QString content = ts.readAll();
    file.close();

    // LRC 时间戳正则: [mm:ss.xx] 或 [mm:ss.xxx]
    QRegularExpression re(R"(\[(\d{1,3}):(\d{2})\.(\d{2,3})\](.*))");

    QStringList lineList = content.split('\n');
    for (const QString &line : lineList) {
        QString trimmed = line.trimmed();
        if (trimmed.isEmpty()) continue;

        // 匹配所有时间戳标签（一行可能有多个，如 [01:00.00][02:00.00]歌词）
        auto matches = re.globalMatch(trimmed);
        QString text;
        QVector<double> times;

        while (matches.hasNext()) {
            auto match = matches.next();
            int min = match.captured(1).toInt();
            int sec = match.captured(2).toInt();
            int ms = match.captured(3).toInt();
            if (match.captured(3).length() == 2) ms *= 10; // 补齐到毫秒

            double time = min * 60.0 + sec + ms / 1000.0;
            times.append(time);
            text = match.captured(4).trimmed();
        }

        // 如果没有匹配到时间戳，跳过这一行
        if (times.isEmpty()) continue;

        // 为每个时间戳创建一行
        for (double t : times) {
            lines_.append({t, text});
        }
    }

    // 按时间戳排序
    std::sort(lines_.begin(), lines_.end(),
              [](const QPair<double, QString> &a, const QPair<double, QString> &b) {
                  return a.first < b.first;
              });

    emit lineCountChanged();
    qDebug() << "Loaded lyrics:" << lines_.size() << "lines from" << path;
    return true;
}

void LyricsParser::clear()
{
    if (lines_.isEmpty()) return;
    lines_.clear();
    emit lineCountChanged();
}

int LyricsParser::lineAt(double seconds) const
{
    if (lines_.isEmpty()) return -1;

    // 二分查找当前时间对应的歌词行
    int lo = 0, hi = lines_.size() - 1;
    int result = -1;

    while (lo <= hi) {
        int mid = (lo + hi) / 2;
        if (lines_[mid].first <= seconds) {
            result = mid;
            lo = mid + 1;
        } else {
            hi = mid - 1;
        }
    }

    return result;
}

double LyricsParser::timeAt(int index) const
{
    if (index < 0 || index >= lines_.size()) return 0.0;
    return lines_[index].first;
}

QString LyricsParser::textAt(int index) const
{
    if (index < 0 || index >= lines_.size()) return QString();
    return lines_[index].second;
}

QString LyricsParser::guessLrcPath(const QString &audioPath)
{
    QFileInfo fi(audioPath);
    QString baseName = fi.completeBaseName();
    QString dir = fi.absolutePath();
    QString lrcPath = dir + "/" + baseName + ".lrc";

    if (QFile::exists(lrcPath)) {
        return lrcPath;
    }

    return QString();
}
