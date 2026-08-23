import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// 歌单列表页：显示用户创建的所有歌单，单击进入歌单详情
// 详情页双击歌曲会加入播放列表并播放
ColumnLayout {
    id: root
    spacing: 8

    // 进入页面时预提取各歌单第一首歌曲封面，完成后刷新缩略图
    Component.onCompleted: window.refreshPlaylistCovers()

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
        objectName: "playlistsListView"
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        model: playlistManager
        spacing: 2

        delegate: Rectangle {
            objectName: "playlistRowDelegate"
            width: playlistsListView.width
            height: 56
            color: plHover.hovered ? "whitesmoke" : "transparent"

            TapHandler {
                // 单击进入歌单详情页（不播放、不添加播放列表）
                onTapped: {
                    playlistManager.currentPlaylistIndex = index
                    window.leftView = "playlistDetail"
                    leftStackView.push(playlistDetailComp)
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

                // 歌单封面：显示歌单内第一首歌曲的内嵌封面，无封面时回退为音符图标
                Rectangle {
                    width: 40
                    height: 40
                    radius: 6
                    color: "limegreen"
                    clip: true
                    Image {
                        id: plCoverImage
                        anchors.fill: parent
                        visible: source !== ""
                        fillMode: Image.PreserveAspectCrop
                        sourceSize: Qt.size(40, 40)
                        source: {
                            // 依赖版本号：封面预提取完成后重新请求图片
                            var _v = window.playlistCoverVersion
                            var p = playlistManager.songFilePath(index, 0)
                            return p === "" ? "" : "image://cover/file/" + encodeURIComponent(p) + "?v=" + _v
                        }
                    }
                    Label {
                        anchors.centerIn: parent
                        visible: !plCoverImage.visible
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

                // 播放按钮：将歌单内全部歌曲加入播放列表并播放第一首
                Button {
                    flat: true
                    implicitWidth: 28
                    implicitHeight: 28
                    onClicked: {
                        var count = playlistManager.playlistSongCount(index)
                        if (count === 0) {
                            window.showToast(qsTr("该歌单为空，请先添加歌曲"))
                            return
                        }
                        playlistModel.clear()
                        for (var i = 0; i < count; i++) {
                            playlistModel.addFile(playlistManager.songFilePath(index, i))
                        }
                        window.currentIndex = 0
                        player.playFile(playlistModel.filePath(0))
                        window.showToast(qsTr("已播放歌单「") + name + qsTr("」"))
                    }
                    contentItem: Label {
                        text: "\u25B6"
                        color: "limegreen"
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: parent.hovered ? "honeydew" : "transparent"
                        radius: 4
                    }
                }

                // 重命名按钮：修改歌单名称
                Button {
                    flat: true
                    implicitWidth: 28
                    implicitHeight: 28
                    onClicked: window.openRenamePlaylistDialog(index, name)
                    contentItem: Label {
                        text: "\u270E"
                        color: "dimgray"
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: parent.hovered ? "honeydew" : "transparent"
                        radius: 4
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
