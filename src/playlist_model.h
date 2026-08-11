#pragma once
#include <QAbstractListModel>
#include <QStringList>
#include <QHash>
#include <QtQml/qqmlregistration.h>

// 歌曲数据项
struct Song
{
    QString filePath;
    QString title;
    QString artist;
    int duration = 0; // 时长（秒）
};

// 播放列表模型：QAbstractListModel，供 QML ListView 显示歌曲列表
class PlaylistModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(int playMode READ playMode WRITE setPlayMode NOTIFY playModeChanged)
public:
    // 播放模式
    enum PlayMode {
        LoopAll = 0,   // 列表循环
        RepeatOne = 1, // 单曲循环
        Shuffle = 2    // 随机播放
    };
    Q_ENUM(PlayMode)

    enum Roles { FilePathRole = Qt::UserRole + 1, TitleRole, ArtistRole, DurationRole };

    explicit PlaylistModel(QObject *parent = nullptr);

    // 添加单个文件路径到列表
    Q_INVOKABLE void addFile(const QString &filePath);
    // 添加多个文件路径
    Q_INVOKABLE void addFiles(const QStringList &filePaths);
    // 移除指定行
    Q_INVOKABLE void remove(int row);
    // 设置指定行歌曲标题（歌单重命名后同步队列显示用）
    Q_INVOKABLE void setTitle(int row, const QString &title);
    // 清空列表
    Q_INVOKABLE void clear();

    // 获取指定行的文件路径
    Q_INVOKABLE QString filePath(int row) const;
    // 判断列表中是否已包含指定文件路径
    Q_INVOKABLE bool contains(const QString &filePath) const;
    // 获取指定文件路径的索引
    Q_INVOKABLE int indexOf(const QString &filePath) const;
    // 当前列表中的歌曲数量
    int count() const;

    // 获取当前播放模式
    int playMode() const { return static_cast<int>(playMode_); }
    // 设置播放模式
    Q_INVOKABLE void setPlayMode(int mode);
    // 切换到下一个播放模式
    Q_INVOKABLE void nextPlayMode();

    // QAbstractListModel 接口
    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

signals:
    void countChanged();
    void playModeChanged();

private:
    QList<Song> songs_;
    PlayMode playMode_ = LoopAll; // 默认列表循环
};
