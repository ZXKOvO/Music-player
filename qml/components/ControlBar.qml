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
