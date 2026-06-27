import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// 底部播放控制栏：播放控制、进度条、音量、倍速
Rectangle {
    id: root
    color: "#1a1a1a"
    height: 56

    function formatTime(sec) {
        if (!isFinite(sec) || sec < 0) return "0:00"
        var m = Math.floor(sec / 60)
        var s = Math.floor(sec % 60)
        return m + ":" + (s < 10 ? "0" : "") + s
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 8
        anchors.bottomMargin: 8
        spacing: 10

        Button {
            implicitWidth: 28
            implicitHeight: 28
            onClicked: fileDialog.open()
            contentItem: Item {
                Image {
                    anchors.centerIn: parent
                    source: "qrc:/qt/qml/MusicPlayer/resources/icons/add.svg"
                    sourceSize.width: 18
                    sourceSize.height: 18
                }
            }
            background: Rectangle {
                color: parent.hovered ? "#444444" : "transparent"
                radius: 4
            }
        }

        // 上一首：|◀
        Button {
            implicitWidth: 24
            implicitHeight: 24
            onClicked: playPrevious()
            contentItem: Item {
                Canvas {
                    anchors.centerIn: parent
                    width: 18
                    height: 18
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.reset()
                        ctx.fillStyle = "#ffffff"
                        ctx.globalAlpha = 0.85
                        // 竖线
                        ctx.fillRect(1, 3, 2, 12)
                        // 左三角
                        ctx.beginPath()
                        ctx.moveTo(16, 3)
                        ctx.lineTo(6, 9)
                        ctx.lineTo(16, 15)
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

        // 播放/暂停：▶ / ❚❚
        Button {
            implicitWidth: 30
            implicitHeight: 30
            onClicked: player.togglePlay()
            contentItem: Item {
                Canvas {
                    anchors.centerIn: parent
                    width: 22
                    height: 22
                    property bool playing: player.playing
                    onPlayingChanged: requestPaint()
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.reset()
                        ctx.fillStyle = "#ffffff"
                        ctx.globalAlpha = 0.85
                        if (playing) {
                            var barW = 3, gap = 4
                            var totalW = barW * 2 + gap
                            var startX = (22 - totalW) / 2
                            ctx.fillRect(startX, 4, barW, 14)
                            ctx.fillRect(startX + barW + gap, 4, barW, 14)
                        } else {
                            ctx.beginPath()
                            ctx.moveTo(5, 2)
                            ctx.lineTo(19, 11)
                            ctx.lineTo(5, 20)
                            ctx.closePath()
                            ctx.fill()
                        }
                    }
                }
            }
            background: Rectangle {
                color: parent.hovered ? "#444444" : "transparent"
                radius: 15
            }
        }

        // 下一首：▶|
        Button {
            implicitWidth: 24
            implicitHeight: 24
            onClicked: playNext()
            contentItem: Item {
                Canvas {
                    anchors.centerIn: parent
                    width: 18
                    height: 18
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.reset()
                        ctx.fillStyle = "#ffffff"
                        ctx.globalAlpha = 0.85
                        // 右三角
                        ctx.beginPath()
                        ctx.moveTo(2, 3)
                        ctx.lineTo(12, 9)
                        ctx.lineTo(2, 15)
                        ctx.closePath()
                        ctx.fill()
                        // 竖线
                        ctx.fillRect(15, 3, 2, 12)
                    }
                }
            }
            background: Rectangle {
                color: parent.hovered ? "#444444" : "transparent"
                radius: 4
            }
        }

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
            implicitWidth: 32
            implicitHeight: 32
            onClicked: playlistModel.nextPlayMode()
            contentItem: Item {
                Image {
                    anchors.centerIn: parent
                    source: playlistModel.playMode === 0 ? "qrc:/qt/qml/MusicPlayer/resources/icons/repeat.svg"
                            : playlistModel.playMode === 1 ? "qrc:/qt/qml/MusicPlayer/resources/icons/repeat-one.svg"
                            : "qrc:/qt/qml/MusicPlayer/resources/icons/shuffle.svg"
                    sourceSize.width: 20
                    sourceSize.height: 20
                }
            }
            background: Rectangle {
                color: parent.hovered ? "#444444" : "transparent"
                radius: 4
            }
        }

        Item { Layout.preferredWidth: 8 }

        Label {
            text: player.title || ""
            color: "#ffffff"
            font.pixelSize: 13
            font.bold: true
            elide: Text.ElideRight
            Layout.preferredWidth: 150
            visible: player.title !== ""
        }

        Label {
            text: formatTime(player.position)
            color: "#cccccc"
            font.pixelSize: 12
            Layout.preferredWidth: 36
            horizontalAlignment: Text.AlignRight
        }

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

        Label {
            text: formatTime(player.duration)
            color: "#cccccc"
            font.pixelSize: 12
            Layout.preferredWidth: 36
        }

        Item { Layout.preferredWidth: 4 }

        Button {
            id: speedBtn
            visible: player.title !== ""
            implicitWidth: 36
            implicitHeight: 28
            onClicked: speedPopup.open()
            contentItem: Label {
                text: player.playbackSpeed.toFixed(1) + "x"
                color: "#b3b3b3"
                font.pixelSize: 12
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

        Button {
            implicitWidth: 28
            implicitHeight: 28
            onClicked: player.toggleMute()
            contentItem: Item {
                Image {
                    anchors.centerIn: parent
                    source: player.muted ? "qrc:/qt/qml/MusicPlayer/resources/icons/volume-mute.svg"
                                         : "qrc:/qt/qml/MusicPlayer/resources/icons/volume.svg"
                    sourceSize.width: 18
                    sourceSize.height: 18
                }
            }
            background: Rectangle {
                color: parent.hovered ? "#444444" : "transparent"
                radius: 4
            }
        }

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
