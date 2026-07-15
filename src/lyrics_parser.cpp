#include "lyrics_parser.h"
#include <QFile>
#include <QTextStream>
#include <QRegularExpression>
#include <QFileInfo>
#include <QDebug>
#include <utility>

LyricsParser::LyricsParser(QObject *parent)
    : QObject(parent)
{}

void LyricsParser::setFilePath(const QString &path)
{
    filePath_ = path;
    emit filePathChanged();

    // 尝试加载同目录下的 .lrc 文件
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

    QTextStream ts(&file);
    ts.setEncoding(QStringConverter::Utf8);
    QString content = ts.readAll();
    file.close();

    if (loadFromString(content)) {
        qDebug() << "Loaded lyrics:" << lines_.size() << "lines from" << path;
        return true;
    }
    return false;
}

// 解析 YRC 逐字歌词格式
// 格式示例: [10140,3720]去(10140,120)到(10260,300)每(10560,150)个人(10860,300)
//   - 行格式: [startMs,durationMs]歌词内容
//   - 字格式: 文字(startMs,durationMs)  文字在括号前面
//   - 多字词(如"个人")会按字数均分 duration
bool LyricsParser::parseYrcContent(const QString &content)
{
    // 行正则: 匹配 [数字,数字]开头的行
    QRegularExpression lineRe(R"(\[(\d+),(\d+)\](.*))");
    // 字正则: 匹配 文字(数字,数字) 格式，文字在括号前
    QRegularExpression wordRe(R"([^(]+)\((\d+),(\d+)\))");

    QStringList lineList = content.split('\n');
    bool found = false;

    for (const QString &line : std::as_const(lineList)) {
        QString trimmed = line.trimmed();
        if (trimmed.isEmpty()) continue;

        // 匹配行级时间 [startMs,durationMs]
        auto lineMatch = lineRe.match(trimmed);
        if (!lineMatch.hasMatch()) continue;

        found = true;
        double lineStartMs = lineMatch.captured(1).toDouble();
        double lineDurationMs = lineMatch.captured(2).toDouble();
        QString rest = lineMatch.captured(3);

        LineInfo li;
        li.startSec = lineStartMs / 1000.0;
        li.durationSec = lineDurationMs / 1000.0;

        // 逐个匹配字级时间 文字(startMs,durationMs)
        int pos = 0;
        while (pos < rest.size()) {
            QRegularExpressionMatch wm = wordRe.match(rest, pos);
            if (!wm.hasMatch()) { break; }

            QString wordText = wm.captured(1);           // 括号前的文字（可能多字）
            double wStartMs = wm.captured(2).toDouble(); // 字开始时间(ms)
            double wDurMs = wm.captured(3).toDouble();   // 字持续时间(ms)

            if (!wordText.isEmpty()) {
                double wStartSec = wStartMs / 1000.0;
                double wDurSec = wDurMs / 1000.0;
                // 多字词按字数均分持续时间
                double charDur = wDurSec / static_cast<double>(wordText.length());

                li.text += wordText;
                for (int c = 0; c < wordText.length(); c++) {
                    li.charInfos.append({wStartSec + c * charDur, charDur});
                }
            }

            pos = static_cast<int>(wm.capturedEnd());
        }

        // 数据一致性检查：charInfos 数量应等于 text 字符数
        if (li.charInfos.size() != static_cast<qsizetype>(li.text.length())) { li.charInfos.clear(); }

        lines_.append(li);
    }

    return found;
}

// 从字符串加载歌词，自动识别 YRC(逐字) 或 LRC(逐行) 格式
bool LyricsParser::loadFromString(const QString &lrcContent)
{
    clear();
    if (lrcContent.isEmpty()) return false;

    // 优先尝试解析 YRC 逐字格式
    if (parseYrcContent(lrcContent)) {
        qDebug() << "Parsed YRC (逐字) lyrics:" << lines_.size() << "lines";
        emit lineCountChanged();
        return true;
    }

    // fallback: 解析标准 LRC 逐行格式 [mm:ss.xx]歌词
    QRegularExpression re(R"(\[(\d{1,3}):(\d{2})\.(\d{2,3})\](.*))");

    QStringList lineList = lrcContent.split('\n');
    for (const QString &line : std::as_const(lineList)) {
        QString trimmed = line.trimmed();
        if (trimmed.isEmpty()) continue;

        auto matches = re.globalMatch(trimmed);
        QString text;
        QVector<double> times;

        while (matches.hasNext()) {
            auto match = matches.next();
            int min = match.captured(1).toInt();
            int sec = match.captured(2).toInt();
            int ms = match.captured(3).toInt();
            if (match.captured(3).length() == 2) ms *= 10;

            double time = min * 60.0 + sec + ms / 1000.0;
            times.append(time);
            text = match.captured(4).trimmed();
        }

        if (times.isEmpty()) continue;

        for (double t : times) {
            LineInfo li;
            li.startSec = t;
            li.durationSec = 0;
            li.text = text;
            lines_.append(li);
        }
    }

    // 按时间排序
    std::sort(lines_.begin(), lines_.end(), [](const LineInfo &a, const LineInfo &b) {
        return a.startSec < b.startSec;
    });

    // 计算每行持续时间（下一行开始时间 - 当前行开始时间）
    for (int i = 0; i < static_cast<int>(lines_.size()) - 1; i++) {
        lines_[i].durationSec = lines_[i + 1].startSec - lines_[i].startSec;
    }
    if (!lines_.isEmpty()) { lines_.last().durationSec = 3.0; }

    // LRC 模式：按字数均分生成 charInfos（等分时间，非真正逐字）
    for (auto &line : lines_) {
        int n = static_cast<int>(line.text.length());
        if (n == 0) continue;
        double dur = line.durationSec / n;
        for (int i = 0; i < n; i++) {
            line.charInfos.append({line.startSec + i * dur, dur});
        }
    }

    emit lineCountChanged();
    return !lines_.isEmpty();
}

// 清空所有歌词行数据
void LyricsParser::clear()
{
    if (lines_.isEmpty()) return;
    lines_.clear();
    emit lineCountChanged();
}

// 二分查找当前播放时间对应的歌词行索引
int LyricsParser::lineAt(double seconds) const
{
    if (lines_.isEmpty()) return -1;

    int lo = 0, hi = static_cast<int>(lines_.size()) - 1;
    int result = -1;

    while (lo <= hi) {
        int mid = (lo + hi) / 2;
        if (lines_[mid].startSec <= seconds) {
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
    if (index < 0 || index >= static_cast<int>(lines_.size())) return 0.0;
    return lines_[index].startSec;
}

QString LyricsParser::textAt(int index) const
{
    if (index < 0 || index >= static_cast<int>(lines_.size())) return QString();
    return lines_[index].text;
}

// 根据播放时间获取当前应高亮的字符索引
// 逐字模式(YRC)：用真实时间戳匹配
// 逐行模式(LRC)：按行内位置等分
int LyricsParser::charIndexAt(double seconds, int lineIndex) const
{
    if (lineIndex < 0 || lineIndex >= static_cast<int>(lines_.size())) return -1;
    const LineInfo &line = lines_[lineIndex];
    if (line.text.isEmpty()) return -1;

    int charCount = static_cast<int>(line.text.length());

    // 逐字模式：charInfos 有真实时间戳，逐个匹配
    if (!line.charInfos.isEmpty() && line.charInfos.size() == charCount) {
        int best = -1;
        for (int i = 0; i < charCount; i++) {
            if (seconds >= line.charInfos[i].startSec) { best = i; }
        }
        return best;
    }

    // 逐行模式 fallback：按行内位置等分
    double lineDuration = line.durationSec;
    if (lineDuration <= 0 || seconds < line.startSec) return -1;

    double progress = (seconds - line.startSec) / lineDuration;
    int idx = static_cast<int>(progress * charCount);
    return qBound(0, idx, charCount - 1);
}

// 根据音频文件路径猜测同名 .lrc 文件
QString LyricsParser::guessLrcPath(const QString &audioPath)
{
    QFileInfo fi(audioPath);
    QString baseName = fi.completeBaseName();
    QString dir = fi.absolutePath();
    QString lrcPath = dir + "/" + baseName + ".lrc";

    if (QFile::exists(lrcPath)) { return lrcPath; }

    return QString();
}
