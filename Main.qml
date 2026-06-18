import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import MusicPlayer

ApplicationWindow {
    id: window
    width: 1000
    height: 500
    visible: true
    title: qsTr("Music Player")
    color: "#2b2b2b"

    property int currentIndex: -1  // 当前播放歌曲索引，-1 表示未选中

    PlaylistModel { id: playlistModel }  // 播放列表数据模型

    PlayerController {
        id: player
        onPlaybackFinished: autoPlayNext()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Top area: playlist + lyrics side by side
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // Left: Playlist panel
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 350
                color: "#ffffff"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    // 播放列表标题栏：显示"播放列表"和歌曲数量
                    RowLayout {
                        Layout.fillWidth: true
                        Label {
                            text: qsTr("播放列表")
                            color: "#000000"
                            font.pixelSize: 18
                            font.bold: true
                        }
                        Label {
                            text: playlistModel.count
                            color: "#666666"
                            font.pixelSize: 16
                        }
                        Item { Layout.fillWidth: true }
                    }

                    // 歌曲列表：双击播放对应歌曲
                    ListView {
                        id: playlistView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: playlistModel
                        currentIndex: window.currentIndex
                        spacing: 2

                        delegate: Rectangle {
                            width: playlistView.width
                            height: 40
                            color: ListView.isCurrentItem ? "#e8e8e8" : (hoverHandler.hovered ? "#f0f0f0" : "transparent")

                            // 双击播放
                            TapHandler {
                                onDoubleTapped: {
                                    window.currentIndex = index
                                    player.playFile(filePath)
                                }
                            }

                            HoverHandler {
                                id: hoverHandler
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 12

                                Label {
                                    text: (index + 1)
                                    color: "#666666"
                                    font.pixelSize: 14
                                    Layout.preferredWidth: 28
                                    horizontalAlignment: Text.AlignRight
                                }

                                Label {
                                    text: {
                                        var artistText = artist || ""
                                        var titleText = title || ""
                                        if (artistText && titleText)
                                            return artistText + " - " + titleText
                                        return titleText
                                    }
                                    color: "#000000"
                                    font.pixelSize: 14
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                        }

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                        }
                    }

                    // 清空播放列表按钮
                    Button {
                        text: qsTr("清空播放列表")
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        flat: true
                        contentItem: Label {
                            text: qsTr("清空播放列表")
                            color: "#888888"
                            font.pixelSize: 14
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: parent.hovered ? "#e8e8e8" : "transparent"
                            radius: 4
                        }
                        onClicked: {
                            playlistModel.clear()
                            window.currentIndex = -1
                            player.stop()
                        }
                    }
                }
            }

            // Divider line
            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                color: "#cccccc"
            }

            // Right: Lyrics area
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#ffffff"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 0

                    ListView {
                        id: lyricsView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: player.lyrics.lineCount
                        highlightFollowsCurrentItem: false

                        property int activeIndex: player.lyrics.lineAt(player.position)

                    delegate: Item {
                        width: lyricsView.width
                        height: 36

                        Label {
                            anchors.centerIn: parent
                            width: parent.width - 20
                            horizontalAlignment: Text.AlignHCenter
                            text: player.lyrics.textAt(index) || ""
                            color: index === lyricsView.activeIndex ? "#1db954" : "#666666"
                            font.pixelSize: index === lyricsView.activeIndex ? 18 : 14
                            font.bold: index === lyricsView.activeIndex
                            wrapMode: Text.Wrap
                        }

                        TapHandler {
                            cursorShape: Qt.PointingHandCursor
                            onTapped: player.seek(player.lyrics.timeAt(index))
                        }
                    }

                        onActiveIndexChanged: {
                            if (activeIndex >= 0) {
                                positionViewAtIndex(activeIndex, ListView.Center)
                            }
                        }
                    }
                }

                // 无歌词提示
                Label {
                    anchors.centerIn: parent
                    visible: player.lyrics.lineCount === 0
                    color: "#999999"
                    font.pixelSize: 20
                    text: player.title ? "暂无歌词" : "请播放歌曲"
                }
            }
        }

        // 底部播放控制栏
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            color: "#1a1a1a"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                anchors.topMargin: 8
                anchors.bottomMargin: 8
                spacing: 10

                // 添加歌曲按钮
                Button {
                    text: qsTr("+ Add")
                    onClicked: fileDialog.open()
                    contentItem: Label {
                        text: qsTr("添加歌曲")
                        color: "#ffffff"
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: parent.hovered ? "#444444" : "#333333"
                        radius: 4
                    }
                }

                // 上一首按钮
                Button {
                    text: qsTr("上一首")
                    onClicked: playPrevious()
                    contentItem: Label {
                        text: qsTr("上一首")
                        color: "#ffffff"
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: parent.hovered ? "#444444" : "#333333"
                        radius: 4
                    }
                }

                // 播放/暂停按钮（根据状态动态切换文字）
                Button {
                    text: player.playing ? qsTr("暂停") : qsTr("播放")
                    onClicked: player.togglePlay()
                    contentItem: Label {
                        text: player.playing ? qsTr("暂停") : qsTr("播放")
                        color: "#ffffff"
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: parent.hovered ? "#444444" : "#333333"
                        radius: 4
                    }
                }

                // 下一首按钮
                Button {
                    text: qsTr("下一首")
                    onClicked: playNext()
                    contentItem: Label {
                        text: qsTr("下一首")
                        color: "#ffffff"
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: parent.hovered ? "#444444" : "#333333"
                        radius: 4
                    }
                }

                // 停止按钮
                Button {
                    text: qsTr("Stop")
                    onClicked: player.stop()
                    contentItem: Label {
                        text: qsTr("刷新")
                        color: "#ffffff"
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: parent.hovered ? "#444444" : "#333333"
                        radius: 4
                    }
                }

                // 播放模式切换按钮
                Button {
                    onClicked: playlistModel.nextPlayMode()
                    contentItem: Label {
                        text: {
                            switch (playlistModel.playMode) {
                            case 0: return "顺序"
                            case 1: return "单曲循环"
                            case 2: return "随机"
                            default: return "顺序"
                            }
                        }
                        color: "#ffffff"
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: parent.hovered ? "#444444" : "#333333"
                        radius: 4
                    }
                }

                Item { Layout.preferredWidth: 8 }

                // 当前播放歌曲信息
                Label {
                    text: player.title || ""
                    color: "#ffffff"
                    font.pixelSize: 13
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.preferredWidth: 150
                    visible: player.title !== ""
                }

                // Current time
                Label {
                    text: formatTime(player.position)
                    color: "#cccccc"
                    font.pixelSize: 12
                    Layout.preferredWidth: 36
                    horizontalAlignment: Text.AlignRight
                }

                // 播放进度条（未选歌时禁用）
                Slider {
                    id: progressSlider
                    Layout.fillWidth: true
                    from: 0
                    to: player.duration || 1
                    value: pressed ? value : player.position
                    enabled: player.title !== ""
                    onMoved: player.seek(value)
                    background: Rectangle {
                        x: progressSlider.leftPadding
                        y: progressSlider.topPadding + progressSlider.availableHeight / 2 - height / 2
                        implicitWidth: 200
                        implicitHeight: 4
                        width: progressSlider.availableWidth
                        height: implicitHeight
                        radius: 2
                        color: "#555555"

                        Rectangle {
                            width: progressSlider.visualPosition * parent.width
                            height: parent.height
                            color: "#1db954"
                            radius: 2
                        }
                    }
                    handle: Rectangle {
                        x: progressSlider.leftPadding + progressSlider.visualPosition * (progressSlider.availableWidth - width)
                        y: progressSlider.topPadding + progressSlider.availableHeight / 2 - height / 2
                        implicitWidth: 14
                        implicitHeight: 14
                        radius: 7
                        color: progressSlider.pressed ? "#1ed760" : "#ffffff"
                    }
                }

                // Total time
                Label {
                    text: formatTime(player.duration)
                    color: "#cccccc"
                    font.pixelSize: 12
                    Layout.preferredWidth: 36
                }

                Item { Layout.preferredWidth: 4 }

                // Mute button
                Button {
                    text: qsTr("Mute")
                    onClicked: player.toggleMute()
                    contentItem: Label {
                        text: player.muted ? qsTr("Unmute") : qsTr("Mute")
                        color: "#ffffff"
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: parent.hovered ? "#444444" : "#333333"
                        radius: 4
                    }
                }

                // 音量调节滑块
                Slider {
                    id: volumeSlider
                    Layout.preferredWidth: 100
                    from: 0
                    to: 1
                    value: player.muted ? 0 : player.volume
                    onMoved: {
                        player.setVolume(value)
                        if (player.muted && value > 0)
                            player.setMuted(false)
                    }
                    background: Rectangle {
                        x: volumeSlider.leftPadding
                        y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                        implicitWidth: 100
                        implicitHeight: 4
                        width: volumeSlider.availableWidth
                        height: implicitHeight
                        radius: 2
                        color: "#555555"

                        Rectangle {
                            width: volumeSlider.visualPosition * parent.width
                            height: parent.height
                            color: "#1db954"
                            radius: 2
                        }
                    }
                    handle: Rectangle {
                        x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                        y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                        implicitWidth: 14
                        implicitHeight: 14
                        radius: 7
                        color: volumeSlider.pressed ? "#1ed760" : "#ffffff"
                    }
                }
            }
        }
    }

    // 文件选择对话框（支持多选）
    FileDialog {
        id: fileDialog
        title: qsTr("Select Audio File")
        fileMode: FileDialog.OpenFiles
        nameFilters: ["Audio Files (*.mp3 *.flac *.wav *.ogg *.aac *.ape)", "All Files (*)"]
        onAccepted: {
            var paths = selectedFiles
            for (var i = 0; i < paths.length; i++) {
                var path = paths[i].toString()
                if (!playlistModel.contains(path)) {
                    playlistModel.addFile(path)
                }
            }
            if (window.currentIndex === -1 && playlistModel.count > 0) {
                window.currentIndex = 0
                player.playFile(playlistModel.filePath(0))
            }
        }
    }

    // 下一首
    function playNext() {
        if (playlistModel.count === 0) return
        var next = window.currentIndex + 1
        if (next >= playlistModel.count) next = 0
        window.currentIndex = next
        player.playFile(playlistModel.filePath(next))
    }

    // 上一首
    function playPrevious() {
        if (playlistModel.count === 0) return
        var prev = window.currentIndex - 1
        if (prev < 0) prev = playlistModel.count - 1
        window.currentIndex = prev
        player.playFile(playlistModel.filePath(prev))
    }

    // 播放完毕自动切歌
    function autoPlayNext() {
        if (playlistModel.count === 0) return
        var next
        switch (playlistModel.playMode) {
        case 0:
            next = window.currentIndex + 1
            if (next >= playlistModel.count) next = 0
            break
        case 1:
            next = window.currentIndex
            break
        case 2:
            next = Math.floor(Math.random() * playlistModel.count)
            if (playlistModel.count > 1) {
                while (next === window.currentIndex) {
                    next = Math.floor(Math.random() * playlistModel.count)
                }
            }
            break
        default:
            next = window.currentIndex
            break
        }
        window.currentIndex = next
        player.playFile(playlistModel.filePath(next))
    }

    // 将秒数格式化为 m:ss
    function formatTime(sec) {
        if (!isFinite(sec) || sec < 0) return "0:00"
        var m = Math.floor(sec / 60)
        var s = Math.floor(sec % 60)
        return m + ":" + (s < 10 ? "0" : "") + s
    }
}
