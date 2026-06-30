import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    color: "#1a1a1a"
    height: 90

    function formatTime(sec) {
        if (!isFinite(sec) || sec < 0) return "0:00"
        var m = Math.floor(sec / 60)
        var s = Math.floor(sec % 60)
        return m + ":" + (s < 10 ? "0" : "") + s
    }

    // 左侧：封面 + 歌曲信息 + 收藏
    RowLayout {
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.top: parent.top
        anchors.topMargin: 10
        spacing: 8

        Rectangle {
            width: 44
            height: 44
            radius: 22
            color: "#333333"
            clip: true

            Image {
                id: coverImage
                anchors.fill: parent
                source: player.hasCover ? "image://cover/current" : ""
                fillMode: Image.PreserveAspectCrop
                cache: false
                asynchronous: true
                visible: status === Image.Ready
            }

            Text {
                anchors.centerIn: parent
                text: "\u266A"
                font.pixelSize: 22
                color: "#666666"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                visible: !coverImage.visible
            }
        }

        ColumnLayout {
            spacing: 4
            opacity: player.title !== "" ? 1 : 0
            Layout.preferredWidth: 140

            Label {
                text: player.title || ""
                color: "#ffffff"
                font.pixelSize: 14
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Label {
                text: player.artist || ""
                color: "#999999"
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
                color: "#ffffff"
                font.pixelSize: 20
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: favoriteBtn.hovered ? "#444444" : "transparent"
                radius: 4
            }
            Layout.leftMargin: 10
        }
    }

    // 中间：进度条 + 播放控制
    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 4
        spacing: 0

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 6

            Label {
                text: formatTime(player.position)
                color: "#cccccc"
                font.pixelSize: 10
                Layout.preferredWidth: 32
                horizontalAlignment: Text.AlignRight
            }

            Slider {
                id: progressSlider
                Layout.preferredWidth: 250
                from: 0
                to: player.duration || 1
                value: pressed ? value : player.position
                enabled: player.title !== ""
                onMoved: player.seek(value)
                background: Rectangle {
                    x: progressSlider.leftPadding
                    y: progressSlider.topPadding + progressSlider.availableHeight / 2 - height / 2
                    implicitWidth: 250
                    implicitHeight: 3
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
                    implicitWidth: 10
                    implicitHeight: 10
                    radius: 5
                    color: progressSlider.pressed ? "#1ed760" : "#ffffff"
                }
            }

            Label {
                text: formatTime(player.duration)
                color: "#cccccc"
                font.pixelSize: 10
                Layout.preferredWidth: 32
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 12

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
                            ctx.fillStyle = "#ffffff"
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
                    color: parent.hovered ? "#444444" : "transparent"
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
                            ctx.fillStyle = "#ffffff"
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
                    color: player.playing ? "#e74c3c" : (parent.hovered ? "#444444" : "#333333")
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
                            ctx.fillStyle = "#ffffff"
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
                    color: parent.hovered ? "#444444" : "transparent"
                    radius: 4
                }
            }

            Button {
                implicitWidth: 26
                implicitHeight: 26
                onClicked: playlistModel.nextPlayMode()
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
                    color: parent.hovered ? "#444444" : "transparent"
                    radius: 4
                }
            }

            Button {
                implicitWidth: 24
                implicitHeight: 24
                onClicked: fileDialog.open()
                contentItem: Item {
                    Image {
                        anchors.centerIn: parent
                        source: "qrc:/qt/qml/MusicPlayer/resources/icons/add.svg"
                        sourceSize.width: 14
                        sourceSize.height: 14
                    }
                }
                background: Rectangle {
                    color: parent.hovered ? "#444444" : "transparent"
                    radius: 4
                }
            }
        }
    }

    // 右侧：音量 + 倍速
    RowLayout {
        anchors.right: parent.right
        anchors.rightMargin: 150
        anchors.top: parent.top
        anchors.topMargin: 10
        spacing: 6

        ColumnLayout {
            spacing: 2

            Slider {
                id: volumeSlider
                Layout.preferredWidth: 16
                Layout.preferredHeight: 28
                orientation: Qt.Vertical
                from: 0
                to: 1
                live: true
                value: player.muted ? 0 : player.volume
                onMoved: {
                    player.setVolume(value)
                    if (player.muted && value > 0)
                        player.setMuted(false)
                }

                background: Item {
                    x: volumeSlider.leftPadding + volumeSlider.availableWidth / 2 - 2
                    y: volumeSlider.topPadding
                    width: 4
                    height: volumeSlider.availableHeight

                    Rectangle {
                        anchors.fill: parent
                        radius: 2
                        color: "#555555"

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width
                            radius: 2
                            color: "#1db954"
                            height: (1 - volumeSlider.visualPosition) * parent.height
                            y: parent.height - height
                        }
                    }
                }

                handle: Rectangle {
                    x: volumeSlider.leftPadding + volumeSlider.availableWidth / 2 - width / 2
                    y: volumeSlider.topPadding + volumeSlider.visualPosition * (volumeSlider.availableHeight - height)
                    width: 10
                    height: 10
                    radius: 5
                    color: volumeSlider.pressed ? "#1ed760" : "#ffffff"
                }
            }

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
                    color: parent.hovered ? "#444444" : "transparent"
                    radius: 4
                }
            }
        }

        Button {
            id: speedBtn
            implicitWidth: 36
            implicitHeight: 28
            onClicked: speedPopup.open()
            contentItem: Label {
                text: player.playbackSpeed.toFixed(1) + "x"
                color: "#b3b3b3"
                font.pixelSize: 11
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
    }
}
