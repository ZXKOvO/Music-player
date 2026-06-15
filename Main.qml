// 主窗口：打开文件 + 播放控制
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import com.musicplayer.backend 1.0

ApplicationWindow {
    id: window
    width: 480
    height: 200
    visible: true
    title: qsTr("Music Player")
    color: "#121212"

    PlayerController { id: player }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        // 歌曲标题 / 提示选歌
        Label {
            text: player.title || ""
            color: "#FFFFFF"
            font.pixelSize: 18
            font.bold: true
            elide: Text.ElideRight
            Layout.fillWidth: true
            visible: player.title !== ""
        }

        Label {
            text: qsTr("Please select a song to play")
            color: "#AAAAAA"
            font.pixelSize: 20
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
            Layout.fillHeight: true
            verticalAlignment: Text.AlignVCenter
            visible: player.title === ""
        }

        // 进度条 + 时间
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Label {
                text: formatTime(player.position)
                color: "#B3B3B3"
                font.pixelSize: 12
            }

            Slider {
                id: progressSlider
                Layout.fillWidth: true
                from: 0
                to: player.duration || 1
                value: pressed ? value : player.position
                onMoved: player.seek(value)
            }

            Label {
                text: formatTime(player.duration)
                color: "#B3B3B3"
                font.pixelSize: 12
            }
        }

        // 控制按钮
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 12

            Button {
                text: qsTr("Open File")
                onClicked: fileDialog.open()
            }

            Button {
                text: player.playing ? qsTr("Pause") : qsTr("Play")
                enabled: player.title !== ""
                onClicked: player.togglePlay()
            }

            Button {
                text: qsTr("Stop")
                enabled: player.title !== ""
                onClicked: player.stop()
            }

            // 静音按钮
            Button {
                text: player.muted ? qsTr("Unmute") : qsTr("Mute")
                onClicked: player.toggleMute()
            }

            // 音量
            Slider {
                width: 100
                from: 0
                to: 1
                value: player.muted ? 0 : player.volume
                onMoved: {
                    player.setVolume(value)
                    if (player.muted && value > 0)
                        player.setMuted(false)
                }
            }
        }

        // 错误提示
        Label {
            text: player.error
            color: "#FF6666"
            font.pixelSize: 12
            visible: player.error !== ""
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
    }

    // 文件选择对话框
    FileDialog {
        id: fileDialog
        title: qsTr("Select Audio File")
        nameFilters: ["Audio Files (*.mp3 *.flac *.wav *.ogg *.aac *.ape)", "All Files (*)"]
        onAccepted: {
            // 使用 QUrl.toLocalFile 正确处理 file:/// 和中文路径
            var path = selectedFile.toString()
            player.playFile(path)
        }
    }

    // 格式化秒数为 mm:ss
    function formatTime(sec) {
        if (!isFinite(sec) || sec < 0) return "0:00"
        var m = Math.floor(sec / 60)
        var s = Math.floor(sec % 60)
        return m + ":" + (s < 10 ? "0" : "") + s
    }
}
