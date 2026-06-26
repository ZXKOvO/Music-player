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
    property string leftView: "main"  // 左侧视图状态："main"播放列表 | "playlists"歌单列表 | "playlistDetail"歌单详情
    property int detailSongCount: 0  // 当前歌单详情中的歌曲数量（驱动 ListView model）
    property int playlistSongVersion: 0  // 歌单歌曲变化版本号，用于强制 QML 刷新绑定

    PlaylistModel { id: playlistModel }  // 播放列表数据模型
    // 歌单管理器：管理用户创建的多个歌单
    PlaylistManager {
        id: playlistManager
        onSongsChanged: {
            playlistSongVersion++  // 歌曲变化时递增，触发 QML 重新求值绑定
            if (currentPlaylistIndex >= 0) {
                detailSongCount = playlistSongCount(currentPlaylistIndex)
            } else {
                detailSongCount = 0
            }
        }
        onCurrentPlaylistIndexChanged: {
            if (currentPlaylistIndex >= 0) {
                detailSongCount = playlistSongCount(currentPlaylistIndex)
            } else {
                detailSongCount = 0
            }
        }
    }

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

            // Left: Playlist panel with view switching
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 350
                color: "#ffffff"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // ===== 顶部导航栏：切换「播放列表」和「我的歌单」视图 =====
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        color: "#f5f5f5"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 4

                            Button {
                                text: qsTr("播放列表")
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                flat: true
                                onClicked: {
                                    window.leftView = "main"
                                    leftStackView.pop(null)
                                }
                                contentItem: Label {
                                    text: qsTr("播放列表")
                                    color: window.leftView === "main" ? "#1db954" : "#666666"
                                    font.pixelSize: 14
                                    font.bold: window.leftView === "main"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                background: Rectangle {
                                    color: "transparent"
                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        width: parent.width
                                        height: 2
                                        color: "#1db954"
                                        visible: window.leftView === "main"
                                    }
                                }
                            }

                            Button {
                                text: qsTr("我的歌单")
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                flat: true
                                onClicked: {
                                    window.leftView = "playlists"
                                    leftStackView.pop(null)
                                    leftStackView.push(playlistsView)
                                }
                                contentItem: Label {
                                    text: qsTr("我的歌单")
                                    color: window.leftView !== "main" ? "#1db954" : "#666666"
                                    font.pixelSize: 14
                                    font.bold: window.leftView !== "main"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                background: Rectangle {
                                    color: "transparent"
                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        width: parent.width
                                        height: 2
                                        color: "#1db954"
                                        visible: window.leftView !== "main"
                                    }
                                }
                            }
                        }
                    }

                    // 分隔线
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: "#e0e0e0"
                    }

                    // 内容区域：StackView 管理三个视图的切换
                    StackView {
                        id: leftStackView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        initialItem: mainPlaylistView

                        // ===== 播放列表视图 =====
                        Component {
                            id: mainPlaylistView
                            ColumnLayout {
                                spacing: 8

                                // 播放列表标题栏
                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 12
                                    Layout.rightMargin: 12
                                    Layout.topMargin: 8
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

                                // 歌曲列表
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
                                    Layout.leftMargin: 8
                                    Layout.rightMargin: 8
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

                        // ===== 歌单列表视图 =====
                        Component {
                            id: playlistsView
                            ColumnLayout {
                                spacing: 8

                                // 标题栏
                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 12
                                    Layout.rightMargin: 12
                                    Layout.topMargin: 8
                                    Label {
                                        text: qsTr("我的歌单")
                                        color: "#000000"
                                        font.pixelSize: 18
                                        font.bold: true
                                    }
                                    Item { Layout.fillWidth: true }
                                    Button {
                                        text: qsTr("+ 新建")
                                        flat: true
                                        onClicked: createPlaylistDialog.open()
                                        contentItem: Label {
                                            text: qsTr("+ 新建")
                                            color: "#1db954"
                                            font.pixelSize: 13
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                        background: Rectangle {
                                            color: parent.hovered ? "#e8f5e9" : "transparent"
                                            radius: 4
                                        }
                                    }
                                }

                                // 歌单列表
                                ListView {
                                    id: playlistsListView
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    clip: true
                                    model: playlistManager
                                    spacing: 2

                                    delegate: Rectangle {
                                        width: playlistsListView.width
                                        height: 56
                                        color: plHover.hovered ? "#f0f0f0" : "transparent"

                                        TapHandler {
                                            onDoubleTapped: {
                                                playlistManager.currentPlaylistIndex = index
                                                window.leftView = "playlistDetail"
                                                leftStackView.push(playlistDetailView)
                                            }
                                        }

                                        HoverHandler {
                                            id: plHover
                                        }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 12
                                            anchors.rightMargin: 12
                                            spacing: 12

                                            // 歌单图标
                                            Rectangle {
                                                width: 40
                                                height: 40
                                                radius: 6
                                                color: "#1db954"
                                                Label {
                                                    anchors.centerIn: parent
                                                    text: "\u266B"
                                                    color: "#ffffff"
                                                    font.pixelSize: 20
                                                }
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 2
                                                Label {
                                                    text: name
                                                    color: "#000000"
                                                    font.pixelSize: 15
                                                    font.bold: true
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }
                                                Label {
                                                    text: songCount + qsTr(" 首歌曲")
                                                    color: "#888888"
                                                    font.pixelSize: 12
                                                }
                                            }

                                            // 删除按钮
                                            Button {
                                                flat: true
                                                implicitWidth: 28
                                                implicitHeight: 28
                                                onClicked: playlistManager.deletePlaylist(index)
                                                contentItem: Label {
                                                    text: "\u2715"
                                                    color: "#cc0000"
                                                    font.pixelSize: 14
                                                    horizontalAlignment: Text.AlignHCenter
                                                    verticalAlignment: Text.AlignVCenter
                                                }
                                                background: Rectangle {
                                                    color: parent.hovered ? "#ffe0e0" : "transparent"
                                                    radius: 4
                                                }
                                            }
                                        }

                                        // 底部分隔线
                                        Rectangle {
                                            anchors.bottom: parent.bottom
                                            width: parent.width
                                            height: 1
                                            color: "#f0f0f0"
                                        }
                                    }

                                    // 空列表提示
                                    Label {
                                        anchors.centerIn: parent
                                        visible: playlistManager.count === 0
                                        text: qsTr("暂无歌单，点击右上角新建")
                                        color: "#999999"
                                        font.pixelSize: 14
                                    }

                                    ScrollBar.vertical: ScrollBar {
                                        policy: ScrollBar.AsNeeded
                                    }
                                }
                            }
                        }

                        // ===== 歌单详情视图 =====
                        Component {
                            id: playlistDetailView
                            ColumnLayout {
                                spacing: 8

                                // 标题栏：返回 + 歌单名
                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 4
                                    Layout.rightMargin: 12
                                    Layout.topMargin: 8
                                    Button {
                                        flat: true
                                        implicitWidth: 32
                                        implicitHeight: 32
                                        onClicked: {
                                            window.leftView = "playlists"
                                            leftStackView.pop()
                                        }
                                        contentItem: Label {
                                            text: "\u2190"
                                            color: "#1db954"
                                            font.pixelSize: 18
                                            font.bold: true
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                        background: Rectangle {
                                            color: parent.hovered ? "#e8f5e9" : "transparent"
                                            radius: 4
                                        }
                                    }
                                    Label {
                                        text: playlistManager.currentPlaylistName
                                        color: "#000000"
                                        font.pixelSize: 18
                                        font.bold: true
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                // 分隔线
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 12
                                    Layout.rightMargin: 12
                                    Layout.preferredHeight: 1
                                    color: "#e0e0e0"
                                }

                                // 歌曲列表
                                ListView {
                                    id: detailSongsView
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    clip: true
                                    spacing: 2

                                    model: window.detailSongCount

                                    delegate: Rectangle {
                                        width: detailSongsView.width
                                        height: 40
                                        color: ListView.isCurrentItem ? "#e8e8e8" : (dtHover.hovered ? "#f0f0f0" : "transparent")

                                        property int songIndex: index
                                        property string songPath: playlistManager.songFilePath(playlistManager.currentPlaylistIndex, index)
                                        property string songName: playlistManager.songTitle(playlistManager.currentPlaylistIndex, index)

                                        TapHandler {
                                            onDoubleTapped: {
                                                // 加入播放列表并播放
                                                if (!playlistModel.contains(songPath)) {
                                                    playlistModel.addFile(songPath)
                                                }
                                                window.currentIndex = playlistModel.count - 1
                                                // 查找已在播放列表中的索引
                                                for (var i = 0; i < playlistModel.count; i++) {
                                                    if (playlistModel.filePath(i) === songPath) {
                                                        window.currentIndex = i
                                                        break
                                                    }
                                                }
                                                player.playFile(songPath)
                                            }
                                        }

                                        HoverHandler {
                                            id: dtHover
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
                                                text: songName
                                                color: "#000000"
                                                font.pixelSize: 14
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }

                                            // 从歌单移除
                                            Button {
                                                flat: true
                                                implicitWidth: 28
                                                implicitHeight: 28
                                                visible: dtHover.hovered
                                                onClicked: playlistManager.removeSongFromCurrentPlaylist(songIndex)
                                                contentItem: Label {
                                                    text: "\u2715"
                                                    color: "#cc0000"
                                                    font.pixelSize: 12
                                                    horizontalAlignment: Text.AlignHCenter
                                                    verticalAlignment: Text.AlignVCenter
                                                }
                                                background: Rectangle {
                                                    color: parent.hovered ? "#ffe0e0" : "transparent"
                                                    radius: 4
                                                }
                                            }
                                        }
                                    }

                                    // 空列表提示
                                    Label {
                                        anchors.centerIn: parent
                                        visible: window.detailSongCount === 0
                                        text: qsTr("暂无歌曲")
                                        color: "#999999"
                                        font.pixelSize: 14
                                    }

                                    ScrollBar.vertical: ScrollBar {
                                        policy: ScrollBar.AsNeeded
                                    }
                                }

                                // 操作按钮栏
                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 8
                                    Layout.rightMargin: 8
                                    spacing: 8

                                    // 从播放列表添加
                                    Button {
                                        text: qsTr("+ 从列表添加")
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 36
                                        flat: true
                                        onClicked: addToPlaylistPopup.open()
                                        contentItem: Label {
                                            text: qsTr("+ 从列表添加")
                                            color: "#1db954"
                                            font.pixelSize: 13
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                        background: Rectangle {
                                            color: parent.hovered ? "#e8f5e9" : "transparent"
                                            radius: 4
                                        }
                                    }

                                    // 从文件导入
                                    Button {
                                        text: qsTr("+ 从文件导入")
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 36
                                        flat: true
                                        onClicked: importFileDialog.open()
                                        contentItem: Label {
                                            text: qsTr("+ 从文件导入")
                                            color: "#1db954"
                                            font.pixelSize: 13
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                        background: Rectangle {
                                            color: parent.hovered ? "#e8f5e9" : "transparent"
                                            radius: 4
                                        }
                                    }
                                }
                            }
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

                        property int lineIdx: index
                        property int activeLine: lyricsView.activeIndex
                        property bool isActive: lineIdx === activeLine
                        property int activeChar: isActive ? player.lyrics.charIndexAt(player.position, activeLine) : -1

                        Row {
                            anchors.centerIn: parent
                            spacing: 0

                            Repeater {
                                model: player.lyrics.textAt(lineIdx) || ""

                                Label {
                                    text: modelData
                                    color: (isActive && index <= activeChar) ? "#1db954" : "#666666"
                                    font.pixelSize: isActive ? 18 : 14
                                    font.bold: isActive && index <= activeChar
                                }
                            }
                        }

                        TapHandler {
                            cursorShape: Qt.PointingHandCursor
                            onTapped: player.seek(player.lyrics.timeAt(lineIdx))
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

                // 倍速切换按钮（竖三点图标，点击弹出滑块）
                Button {
                    id: speedBtn
                    visible: player.title !== ""
                    implicitWidth: 32
                    implicitHeight: 28
                    onClicked: speedPopup.open()
                    contentItem: Label {
                        text: "\u22EE"
                        color: "#ffffff"
                        font.pixelSize: 18
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: speedBtn.hovered ? "#444444" : "transparent"
                        radius: 4
                    }
                    Popup {
                        id: speedPopup
                        y: -height - 8
                        x: (parent.width - width) / 2
                        padding: 12
                        background: Rectangle {
                            color: "#2a2a2a"
                            radius: 8
                            border.color: "#444444"
                            border.width: 1
                        }
                        contentItem: ColumnLayout {
                            spacing: 8
                            Label {
                                text: player.playbackSpeed.toFixed(1) + "x"
                                color: "#ffffff"
                                font.pixelSize: 14
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                Layout.fillWidth: true
                            }
                            Slider {
                                id: speedSlider
                                from: 0.5
                                to: 2.0
                                stepSize: 0.1
                                value: player.playbackSpeed
                                Layout.preferredWidth: 160
                                onValueChanged: {
                                    if (pressed) player.setPlaybackSpeed(value)
                                }
                                background: Rectangle {
                                    x: speedSlider.leftPadding
                                    y: speedSlider.topPadding + speedSlider.availableHeight / 2 - height / 2
                                    implicitHeight: 4
                                    width: speedSlider.availableWidth
                                    height: implicitHeight
                                    radius: 2
                                    color: "#555555"
                                    Rectangle {
                                        width: speedSlider.visualPosition * parent.width
                                        height: parent.height
                                        color: "#1db954"
                                        radius: 2
                                    }
                                }
                                handle: Rectangle {
                                    x: speedSlider.leftPadding + speedSlider.visualPosition * (speedSlider.availableWidth - width)
                                    y: speedSlider.topPadding + speedSlider.availableHeight / 2 - height / 2
                                    implicitWidth: 16
                                    implicitHeight: 16
                                    radius: 8
                                    color: speedSlider.pressed ? "#1ed760" : "#ffffff"
                                }
                            }
                        }
                    }
                }

                // 收藏到歌单按钮：点击弹出歌单列表，将当前播放歌曲加入选中歌单
                Button {
                    id: favoriteBtn
                    visible: player.title !== ""
                    implicitWidth: 32
                    implicitHeight: 28
                    onClicked: {
                        if (playlistManager.count === 0) {
                            createPlaylistDialog.open()
                        } else {
                            favoritePopup.open()
                        }
                    }
                    contentItem: Label {
                        text: "\u2606"
                        color: "#ffffff"
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: favoriteBtn.hovered ? "#444444" : "transparent"
                        radius: 4
                    }
                }

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

    // ===== 新建歌单对话框 =====
    Dialog {
        id: createPlaylistDialog
        title: qsTr("新建歌单")
        anchors.centerIn: parent
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel
        width: 320
        onOpened: playlistNameInput.text = ""
        onAccepted: {
            var name = playlistNameInput.text.trim()
            if (name.length > 0) {
                playlistManager.createPlaylist(name)
            }
        }
        contentItem: ColumnLayout {
            spacing: 12
            Label {
                text: qsTr("请输入歌单名称：")
                color: "#000000"
                font.pixelSize: 14
            }
            TextField {
                id: playlistNameInput
                Layout.fillWidth: true
                placeholderText: qsTr("歌单名称")
                maximumLength: 30
                onAccepted: createPlaylistDialog.accept()
            }
        }
    }

    // ===== 向当前歌单添加歌曲的弹出列表（从播放列表中选择） =====
    Popup {
        id: addToPlaylistPopup
        anchors.centerIn: parent
        width: 360
        height: Math.min(400, addToPlaylistColumn.height + 24)
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: "#ffffff"
            radius: 8
            border.color: "#e0e0e0"
            border.width: 1
        }

        contentItem: ColumnLayout {
            id: addToPlaylistColumn
            spacing: 0

            // 标题
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                Layout.topMargin: 12
                Layout.bottomMargin: 8
                Label {
                    text: qsTr("添加歌曲到：") + playlistManager.currentPlaylistName
                    color: "#000000"
                    font.pixelSize: 15
                    font.bold: true
                    Layout.fillWidth: true
                }
                Button {
                    flat: true
                    implicitWidth: 24
                    implicitHeight: 24
                    onClicked: addToPlaylistPopup.close()
                    contentItem: Label {
                        text: "\u2715"
                        color: "#666666"
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            // 分隔线
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: "#e0e0e0"
            }

            // 主播放列表歌曲（可添加的）
            ListView {
                id: addSongListView
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(340, playlistModel.count * 40 + 8)
                clip: true
                model: playlistModel
                spacing: 0

                delegate: Rectangle {
                    width: addSongListView.width
                    height: 40
                    color: addSongHover.hovered ? "#f0f0f0" : "transparent"

                    property bool alreadyAdded: {
                        var _v = window.playlistSongVersion
                        return playlistManager.containsSong(playlistManager.currentPlaylistIndex, filePath)
                    }

                    TapHandler {
                        onTapped: {
                            if (!alreadyAdded) {
                                playlistManager.addSongToCurrentPlaylist(filePath)
                            }
                        }
                    }

                    HoverHandler {
                        id: addSongHover
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        Label {
                            text: title || ""
                            color: alreadyAdded ? "#cccccc" : "#000000"
                            font.pixelSize: 14
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Label {
                            text: alreadyAdded ? qsTr("已添加") : qsTr("添加")
                            color: alreadyAdded ? "#cccccc" : "#1db954"
                            font.pixelSize: 12
                        }
                    }
                }

                // 空列表提示
                Label {
                    anchors.centerIn: parent
                    visible: playlistModel.count === 0
                    text: qsTr("播放列表为空，请先添加歌曲")
                    color: "#999999"
                    font.pixelSize: 13
                }
            }
        }
    }

    // ===== 收藏到歌单弹出列表：将当前播放歌曲收藏到任意歌单 =====
    Popup {
        id: favoritePopup
        anchors.centerIn: parent
        width: 300
        height: Math.min(360, favoriteColumn.height + 24)
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: "#ffffff"
            radius: 8
            border.color: "#e0e0e0"
            border.width: 1
        }

        contentItem: ColumnLayout {
            id: favoriteColumn
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                Layout.topMargin: 12
                Layout.bottomMargin: 8
                Label {
                    text: qsTr("收藏到歌单")
                    color: "#000000"
                    font.pixelSize: 15
                    font.bold: true
                    Layout.fillWidth: true
                }
                Button {
                    flat: true
                    implicitWidth: 24
                    implicitHeight: 24
                    onClicked: favoritePopup.close()
                    contentItem: Label {
                        text: "\u2715"
                        color: "#666666"
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: "#e0e0e0"
            }

            Label {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                Layout.topMargin: 4
                text: player.title || ""
                color: "#888888"
                font.pixelSize: 12
                elide: Text.ElideRight
            }

            ListView {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(300, playlistManager.count * 44 + 8)
                clip: true
                model: playlistManager
                spacing: 0

                delegate: Rectangle {
                    width: favoritePopup.width
                    height: 44
                    color: favHover.hovered ? "#f0f0f0" : "transparent"

                    property bool alreadyIn: {
                        var _v = window.playlistSongVersion
                        var curFile = playlistModel.filePath(window.currentIndex)
                        return curFile !== "" && playlistManager.containsSong(index, curFile)
                    }

                    TapHandler {
                        onTapped: {
                            if (!alreadyIn) {
                                var curFile = playlistModel.filePath(window.currentIndex)
                                if (curFile !== "") {
                                    playlistManager.addSongToPlaylist(index, curFile)
                                }
                            }
                        }
                    }

                    HoverHandler { id: favHover }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10

                        Rectangle {
                            width: 32
                            height: 32
                            radius: 4
                            color: "#1db954"
                            Label {
                                anchors.centerIn: parent
                                text: "\u266B"
                                color: "#ffffff"
                                font.pixelSize: 16
                            }
                        }

                        Label {
                            text: name
                            color: "#000000"
                            font.pixelSize: 14
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Label {
                            text: alreadyIn ? qsTr("已收藏") : ""
                            color: "#cccccc"
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }
    }

    // ===== 从文件导入到当前歌单的文件对话框 =====
    FileDialog {
        id: importFileDialog
        title: qsTr("导入歌曲到歌单")
        fileMode: FileDialog.OpenFiles
        nameFilters: ["Audio Files (*.mp3 *.flac *.wav *.ogg *.aac *.ape)", "All Files (*)"]
        onAccepted: {
            var paths = selectedFiles
            for (var i = 0; i < paths.length; i++) {
                var path = paths[i].toString()
                playlistManager.addSongToCurrentPlaylist(path)
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
