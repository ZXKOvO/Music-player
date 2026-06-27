import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// 歌单列表页：显示用户创建的所有歌单
// 单击加入播放列表，双击进入歌单详情
ColumnLayout {
    id: root
    spacing: 8
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

    // Playlist list
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
                    leftStackView.push(playlistDetailComp)
                }
                onTapped: {
                    playlistManager.currentPlaylistIndex = index
                    var count = playlistManager.playlistSongCount(index)
                    for (var i = 0; i < count; i++) {
                        var path = playlistManager.songFilePath(index, i)
                        if (!playlistModel.contains(path)) {
                            playlistModel.addFile(path)
                        }
                    }
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

                Button {
                    flat: true
                    implicitWidth: 28
                    implicitHeight: 28
                    onClicked: deletePlaylistConfirmDialog.openWithIndex(index, name)
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

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: "#f0f0f0"
            }
        }

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

    // Delete playlist confirmation dialog
    Dialog {
        id: deletePlaylistConfirmDialog
        title: qsTr("删除歌单")
        anchors.centerIn: parent
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel
        width: 320

        property int targetIndex: -1
        property string playlistName: ""

        function openWithIndex(idx, name) {
            targetIndex = idx
            playlistName = name
            open()
        }

        onAccepted: {
            if (targetIndex >= 0) {
                playlistManager.deletePlaylist(targetIndex)
                targetIndex = -1
                playlistName = ""
            }
        }
        onRejected: {
            targetIndex = -1
            playlistName = ""
        }

        contentItem: ColumnLayout {
            spacing: 12
            Label {
                text: qsTr("确定要删除歌单「") + deletePlaylistConfirmDialog.playlistName + qsTr("」吗？\n删除后歌单内的歌曲将无法恢复。")
                color: "#000000"
                font.pixelSize: 14
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }
    }
}
