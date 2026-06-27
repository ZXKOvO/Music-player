import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// 歌单详情页：查看某个歌单内的歌曲，支持添加/移除
ColumnLayout {
    id: root
    spacing: 8
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

    // Separator
    Rectangle {
        Layout.fillWidth: true
        Layout.leftMargin: 12
        Layout.rightMargin: 12
        Layout.preferredHeight: 1
        color: "#e0e0e0"
    }

    // Song list
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
                    if (!playlistModel.contains(songPath)) {
                        playlistModel.addFile(songPath)
                    }
                    window.currentIndex = playlistModel.count - 1
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

                Button {
                    flat: true
                    implicitWidth: 28
                    implicitHeight: 28
                    visible: dtHover.hovered
                    onClicked: removeSongConfirmDialog.openWithIndex(songIndex)
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

    // Action buttons
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 8
        Layout.rightMargin: 8
        spacing: 8

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

    // Remove song confirmation dialog
    Dialog {
        id: removeSongConfirmDialog
        title: qsTr("移除歌曲")
        anchors.centerIn: parent
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel
        width: 320

        property int targetIndex: -1

        function openWithIndex(idx) {
            targetIndex = idx
            open()
        }

        onAccepted: {
            if (targetIndex >= 0) {
                playlistManager.removeSongFromCurrentPlaylist(targetIndex)
                targetIndex = -1
            }
        }
        onRejected: targetIndex = -1

        contentItem: ColumnLayout {
            spacing: 12
            Label {
                text: qsTr("确定要从歌单中移除这首歌曲吗？")
                color: "#000000"
                font.pixelSize: 14
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }
    }
}
