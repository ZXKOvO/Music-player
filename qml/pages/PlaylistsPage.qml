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
            color: "black"
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
                color: "limegreen"
                font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: parent.hovered ? "honeydew" : "transparent"
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
            color: plHover.hovered ? "whitesmoke" : "transparent"

            TapHandler {
                // 双击进入歌单详情页
                onDoubleTapped: {
                    playlistManager.currentPlaylistIndex = index
                    window.leftView = "playlistDetail"
                    leftStackView.push(playlistDetailComp)
                }
                // 单击将歌单歌曲加载到播放列表并播放第一首
                onTapped: {
                    playlistManager.currentPlaylistIndex = index
                    var count = playlistManager.playlistSongCount(index)
                    if (count === 0) return
                    playlistModel.clear()
                    for (var i = 0; i < count; i++) {
                        playlistModel.addFile(playlistManager.songFilePath(index, i))
                    }
                    window.currentIndex = 0
                    player.playFile(playlistModel.filePath(0))
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
                    color: "limegreen"
                    Label {
                        anchors.centerIn: parent
                        text: "\u266B"
                        color: "white"
                        font.pixelSize: 20
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Label {
                        text: name
                        color: "black"
                        font.pixelSize: 15
                        font.bold: true
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Label {
                        text: songCount + qsTr(" 首歌曲")
                        color: "gray"
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
                        color: "red"
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: parent.hovered ? "mistyrose" : "transparent"
                        radius: 4
                    }
                }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: "whitesmoke"
            }
        }

        Label {
            anchors.centerIn: parent
            visible: playlistManager.count === 0
            text: qsTr("暂无歌单，点击右上角新建")
            color: "gray"
            font.pixelSize: 14
        }

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }
    }

    // Delete playlist confirmation dialog
    ConfirmDialog {
        id: deletePlaylistConfirmDialog
        title: qsTr("删除歌单")

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
                color: "black"
                font.pixelSize: 14
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }
    }
}
