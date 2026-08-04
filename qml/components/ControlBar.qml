import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

// 底部控制栏：播放控制、进度条、音量、播放模式等
Rectangle {
    id: root
    color: "black"

    // 双击切换全屏
    TapHandler {
        onDoubleTapped: {
            if (window.visibility === Window.FullScreen) {
                window.showNormal()
            } else {
                window.showFullScreen()
            }
        }
    }

    // 将秒数格式化为 "m:ss" 格式（如 65 → "1:05"）
    function formatTime(sec) {
        if (!isFinite(sec) || sec < 0) return "0:00"
        var m = Math.floor(sec / 60)
        var s = Math.floor(sec % 60)
        return m + ":" + (s < 10 ? "0" : "") + s
    }

    // 主布局：左侧歌曲信息 + 中间控制按钮 + 右侧功能按钮
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 150
        anchors.topMargin: 4
        spacing: 12

        // 左侧：封面 + 歌曲信息 + 收藏
        RowLayout {
            Layout.fillWidth: false
            Layout.preferredWidth: 220
            Layout.alignment: Qt.AlignVCenter
            spacing: 8

            Rectangle {
                id: coverHolder
                width: 44
                height: 44
                radius: 22
                color: "dimgray"
                clip: true

                Image {
                    id: coverImage
                    anchors.fill: parent
                    source: player.hasCover ? "image://cover/circle" : ""
                    sourceSize: Qt.size(44, 44)
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    asynchronous: true
                    visible: status === Image.Ready
                    // 播放时封面顺时针旋转
                    rotation: parent.coverSpinAngle
                }

                // 封面旋转：播放中每帧顺时针旋转，暂停/停止时停住
                property real coverSpinAngle: 0
                Timer {
                    interval: 16
                    repeat: true
                    running: player.playing && coverImage.visible
                    onTriggered: parent.coverSpinAngle = (parent.coverSpinAngle + 0.5) % 360
                }

                // 切换歌曲时封面重新从 0° 开始旋转
                Connections {
                    target: player
                    function onTitleChanged() { coverHolder.coverSpinAngle = 0 }
                }

                Text {
                    anchors.centerIn: parent
                    text: "\u266A"
                    font.pixelSize: 22
                    color: "dimgray"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    visible: !coverImage.visible
                }
            }

            ColumnLayout {
                spacing: 4
                opacity: player.title !== "" ? 1 : 0
                Layout.fillWidth: true

                Label {
                    text: player.title || ""
                    color: "white"
                    font.pixelSize: 14
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Label {
                    text: player.artist || ""
                    color: "gray"
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            Button {
                id: favoriteBtn
                opacity: player.title !== "" ? 1 : 0
                implicitWidth: 36
                implicitHeight: 36
                enabled: player.title !== ""
                onClicked: {
                    if (playlistManager.count === 0) {
                        createPlaylistDialog.open()
                    } else {
                        favoritePopup.open()
                    }
                }
                contentItem: Label {
                    text: "\u2606"
                    color: "white"
                    font.pixelSize: 20
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: favoriteBtn.hovered ? "dimgray" : "transparent"
                    radius: 4
                }
            }
        }

        // 中间：进度条 + 播放控制
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            // 进度条：显示播放进度，支持拖动
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 6

                Label {
                    text: formatTime(player.position)
                    color: "lightgray"
                    font.pixelSize: 10
                    Layout.preferredWidth: 32
                    horizontalAlignment: Text.AlignRight
                }

                // 播放进度条：拖动时实时更新，松手后触发 seek
                Slider {
                    id: progressSlider
                    Layout.fillWidth: true
                    from: 0
                    to: player.duration || 1
                    value: pressed ? value : player.position  // 拖动中保持手柄位置
                    enabled: player.title !== ""
                    onMoved: player.seek(value)
                    background: Rectangle {
                        x: progressSlider.leftPadding
                        y: progressSlider.topPadding + progressSlider.availableHeight / 2 - height / 2
                        implicitHeight: 3
                        width: progressSlider.availableWidth
                        height: implicitHeight
                        radius: 2
                        color: "gray"

                        Rectangle {
                            width: progressSlider.visualPosition * parent.width
                            height: parent.height
                            color: "limegreen"
                            radius: 2
                        }
                    }
                    handle: Rectangle {
                        x: progressSlider.leftPadding + progressSlider.visualPosition * (progressSlider.availableWidth - width)
                        y: progressSlider.topPadding + progressSlider.availableHeight / 2 - height / 2
                        implicitWidth: 10
                        implicitHeight: 10
                        radius: 5
                        color: progressSlider.pressed ? "limegreen" : "white"
                    }
                }

                Label {
                    text: formatTime(player.duration)
                    color: "lightgray"
                    font.pixelSize: 10
                    Layout.preferredWidth: 32
                }
            }

            // 播放控制按钮行：停止 | 上一首 | 播放/暂停 | 下一首 | 播放模式 | 添加文件
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 12

                Button {
                    text: qsTr("Stop")
                    onClicked: player.stop()
                    contentItem: Label {
                        text: qsTr("刷新")
                        color: "white"
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: parent.hovered ? "dimgray" : "dimgray"
                        radius: 4
                    }
                }

                Button {
                    implicitWidth: 26
                    implicitHeight: 26
                    onClicked: playPrevious()
                    contentItem: Item {
                        Canvas {
                            anchors.centerIn: parent
                            width: 16
                            height: 16
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.reset()
                                ctx.fillStyle = "white"
                                ctx.globalAlpha = 0.85
                                ctx.fillRect(1, 2, 2, 12)
                                ctx.beginPath()
                                ctx.moveTo(14, 2)
                                ctx.lineTo(5, 8)
                                ctx.lineTo(14, 14)
                                ctx.closePath()
                                ctx.fill()
                            }
                        }
                    }
                    background: Rectangle {
                        color: parent.hovered ? "dimgray" : "transparent"
                        radius: 4
                    }
                }

                Button {
                    implicitWidth: 34
                    implicitHeight: 34
                    onClicked: player.togglePlay()
                    contentItem: Item {
                        Canvas {
                            anchors.centerIn: parent
                            width: 20
                            height: 20
                            property bool playing: player.playing
                            onPlayingChanged: requestPaint()
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.reset()
                                ctx.fillStyle = "white"
                                ctx.globalAlpha = 0.85
                                if (playing) {
                                    var barW = 3, gap = 3
                                    var totalW = barW * 2 + gap
                                    var startX = (20 - totalW) / 2
                                    ctx.fillRect(startX, 3, barW, 14)
                                    ctx.fillRect(startX + barW + gap, 3, barW, 14)
                                } else {
                                    ctx.beginPath()
                                    ctx.moveTo(4, 2)
                                    ctx.lineTo(16, 10)
                                    ctx.lineTo(4, 18)
                                    ctx.closePath()
                                    ctx.fill()
                                }
                            }
                        }
                    }
                    background: Rectangle {
                        color: player.playing ? "red" : (parent.hovered ? "dimgray" : "dimgray")
                        radius: 17
                    }
                }

                Button {
                    implicitWidth: 26
                    implicitHeight: 26
                    onClicked: playNext()
                    contentItem: Item {
                        Canvas {
                            anchors.centerIn: parent
                            width: 16
                            height: 16
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.reset()
                                ctx.fillStyle = "white"
                                ctx.globalAlpha = 0.85
                                ctx.beginPath()
                                ctx.moveTo(2, 2)
                                ctx.lineTo(11, 8)
                                ctx.lineTo(2, 14)
                                ctx.closePath()
                                ctx.fill()
                                ctx.fillRect(13, 2, 2, 12)
                            }
                        }
                    }
                    background: Rectangle {
                        color: parent.hovered ? "dimgray" : "transparent"
                        radius: 4
                    }
                }

                Button {
                    id: playModeBtn
                    implicitWidth: 26
                    implicitHeight: 26
                    onClicked: {
                        playlistModel.nextPlayMode()
                        var modeNames = [qsTr("列表循环"), qsTr("单曲循环"), qsTr("随机播放")]
                        modeToolTip.text = modeNames[playlistModel.playMode]
                        modeToolTip.visible = true
                        modeToolTipTimer.restart()
                    }
                    contentItem: Item {
                        Image {
                            anchors.centerIn: parent
                            source: playlistModel.playMode === 0 ? "qrc:/qt/qml/MusicPlayer/resources/icons/repeat.svg"
                                    : playlistModel.playMode === 1 ? "qrc:/qt/qml/MusicPlayer/resources/icons/repeat-one.svg"
                                    : "qrc:/qt/qml/MusicPlayer/resources/icons/shuffle.svg"
                            sourceSize.width: 16
                            sourceSize.height: 16
                        }
                    }
                    background: Rectangle {
                        color: parent.hovered ? "dimgray" : "transparent"
                        radius: 4
                    }

                    Rectangle {
                        id: modeToolTip
                        property string text: ""
                        visible: false
                        anchors.bottom: parent.top
                        anchors.bottomMargin: 4
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: modeToolTipLabel.implicitWidth + 16
                        height: 24
                        color: Qt.rgba(0.2, 0.2, 0.2, 0.2)
                        radius: 4

                        Label {
                            id: modeToolTipLabel
                            anchors.centerIn: parent
                            text: modeToolTip.text
                            color: "white"
                            font.pixelSize: 11
                        }
                    }

                    Timer {
                        id: modeToolTipTimer
                        interval: 1500
                        onTriggered: modeToolTip.visible = false
                    }
                }

                Button {
                    implicitWidth: 24
                    implicitHeight: 24
                    onClicked: window.openFileDialog()
                    contentItem: Item {
                        Image {
                            anchors.centerIn: parent
                            source: "qrc:/qt/qml/MusicPlayer/resources/icons/add.svg"
                            sourceSize.width: 14
                            sourceSize.height: 14
                        }
                    }
                    background: Rectangle {
                        color: parent.hovered ? "dimgray" : "transparent"
                        radius: 4
                    }
                }
            }
        }

            // 右侧功能区：音量 | 播放列表 | 桌面歌词 | 倍速
            RowLayout {
                Layout.fillWidth: false
                Layout.preferredWidth: 200
                Layout.alignment: Qt.AlignVCenter
                spacing: 6

                // 音量控制：静音按钮 + 音量滑块
            RowLayout {
                spacing: 4

                Button {
                    implicitWidth: 20
                    implicitHeight: 20
                    onClicked: player.toggleMute()
                    contentItem: Item {
                        Image {
                            anchors.centerIn: parent
                            source: player.muted ? "qrc:/qt/qml/MusicPlayer/resources/icons/volume-mute.svg"
                                                 : "qrc:/qt/qml/MusicPlayer/resources/icons/volume.svg"
                            sourceSize.width: 12
                            sourceSize.height: 12
                        }
                    }
                    background: Rectangle {
                        color: parent.hovered ? "dimgray" : "transparent"
                        radius: 4
                    }
                }

                Slider {
                    id: volumeSlider
                    Layout.preferredWidth: 80
                    Layout.preferredHeight: 20
                    orientation: Qt.Horizontal
                    from: 0
                    to: 1
                    live: true
                    value: player.muted ? 0 : player.volume
                    onMoved: {
                        player.setVolume(value)
                        if (player.muted && value > 0)
                            player.setMuted(false)
                    }

                    background: Rectangle {
                        x: volumeSlider.leftPadding
                        y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                        implicitHeight: 3
                        width: volumeSlider.availableWidth
                        height: implicitHeight
                        radius: 2
                        color: "gray"

                        Rectangle {
                            width: volumeSlider.visualPosition * parent.width
                            height: parent.height
                            color: "limegreen"
                            radius: 2
                        }
                    }

                    handle: Rectangle {
                        x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                        y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                        implicitWidth: 10
                        implicitHeight: 10
                        radius: 5
                        color: volumeSlider.pressed ? "limegreen" : "white"
                    }
                }
            }

            // 播放列表按钮
            Button {
                id: playlistToggleBtn
                implicitWidth: 24
                implicitHeight: 24
                onClicked: playlistSidebar.isOpen = !playlistSidebar.isOpen
                contentItem: Item {
                    Image {
                        anchors.centerIn: parent
                        source: "qrc:/qt/qml/MusicPlayer/resources/icons/playlist.svg"
                        sourceSize.width: 16
                        sourceSize.height: 16
                    }
                }
                background: Rectangle {
                    color: playlistToggleBtn.hovered ? "dimgray" : "transparent"
                    radius: 4
                }
                ToolTip.text: qsTr("播放列表")
                ToolTip.visible: playlistToggleBtn.hovered
            }

            // 桌面歌词按钮
            Button {
                id: desktopLyricsBtn
                implicitWidth: 24
                implicitHeight: 24
                onClicked: player.showDesktopLyrics = !player.showDesktopLyrics
                contentItem: Item {
                    Label {
                        anchors.centerIn: parent
                        text: "\u266B"
                        color: player.showDesktopLyrics ? "limegreen" : "white"
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
                background: Rectangle {
                    color: desktopLyricsBtn.hovered ? "dimgray" : "transparent"
                    radius: 4
                }
                ToolTip.text: player.showDesktopLyrics ? qsTr("关闭桌面歌词") : qsTr("开启桌面歌词")
                ToolTip.visible: desktopLyricsBtn.hovered
            }

            // 倍速调节按钮
            Button {
                id: speedBtn
                implicitWidth: 36
                implicitHeight: 28
                onClicked: speedPopup.open()
                contentItem: Label {
                    text: player.playbackSpeed.toFixed(1) + "x"
                    color: "gray"
                    font.pixelSize: 11
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: speedBtn.hovered ? "dimgray" : "transparent"
                    radius: 4
                }
                // 倍速调节弹窗
                Popup {
                    id: speedPopup
                    y: -height - 8
                    x: (parent.width - width) / 2
                    padding: 12
                    background: Rectangle {
                        color: "black"
                        radius: 8
                        border.color: "dimgray"
                        border.width: 1
                    }
                    contentItem: ColumnLayout {
                        spacing: 8
                        Label {
                            text: player.playbackSpeed.toFixed(1) + "x"
                            color: "white"
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
                                color: "gray"
                                Rectangle {
                                    width: speedSlider.visualPosition * parent.width
                                    height: parent.height
                                    color: "limegreen"
                                    radius: 2
                                }
                            }
                            handle: Rectangle {
                                x: speedSlider.leftPadding + speedSlider.visualPosition * (speedSlider.availableWidth - width)
                                y: speedSlider.topPadding + speedSlider.availableHeight / 2 - height / 2
                                implicitWidth: 16
                                implicitHeight: 16
                                radius: 8
                                color: speedSlider.pressed ? "limegreen" : "white"
                            }
                        }
                    }
                }
            }
        }
    }
}
