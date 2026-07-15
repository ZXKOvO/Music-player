import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// 主播放列表页面，从 Main.qml 拆出
// 通过上下文链访问 player / playlistModel / window
ColumnLayout {
    id: root
    spacing: 8
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 12
        Layout.rightMargin: 12
        Layout.topMargin: 8
        Label {
            text: qsTr("播放列表")
            color: "black"
            font.pixelSize: 18
            font.bold: true
        }
        Label {
            text: playlistModel.count
            color: "dimgray"
            font.pixelSize: 16
        }
        Item { Layout.fillWidth: true }
    }

    // Song list
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
            color: ListView.isCurrentItem ? "lightgray" : (hoverHandler.hovered ? "whitesmoke" : "transparent")

            // 双击播放列表中的歌曲
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
                    color: "dimgray"
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
            color: "black"
                    font.pixelSize: 14
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Button {
                    flat: true
                    implicitWidth: 28
                    implicitHeight: 28
                    visible: hoverHandler.hovered
                    onClicked: removeSongFromPlaylistDialog.openWithIndex(index)
                    contentItem: Label {
                        text: "\u2715"
                        color: "red"
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: parent.hovered ? "mistyrose" : "transparent"
                        radius: 4
                    }
                }
            }
        }

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }
    }

    // Clear playlist button
    Button {
        text: qsTr("清空播放列表")
        Layout.fillWidth: true
        Layout.preferredHeight: 36
        Layout.leftMargin: 8
        Layout.rightMargin: 8
        flat: true
        contentItem: Label {
            text: qsTr("清空播放列表")
            color: "gray"
            font.pixelSize: 14
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            color: parent.hovered ? "lightgray" : "transparent"
            radius: 4
        }
        onClicked: clearPlaylistDialog.open()
    }

    // Remove song confirmation dialog
    Dialog {
        id: removeSongFromPlaylistDialog
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
                var removedIndex = targetIndex
                playlistModel.remove(removedIndex)
                if (removedIndex === window.currentIndex) {
                    player.stop()
                    window.currentIndex = -1
                } else if (removedIndex < window.currentIndex) {
                    window.currentIndex--
                }
                targetIndex = -1
            }
        }
        onRejected: targetIndex = -1

        contentItem: ColumnLayout {
            spacing: 12
            Label {
                text: qsTr("确定要从播放列表中移除这首歌曲吗？")
                color: "black"
                font.pixelSize: 14
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }
    }

    // Clear playlist confirmation dialog
    Dialog {
        id: clearPlaylistDialog
        title: qsTr("清空播放列表")
        anchors.centerIn: parent
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel
        width: 320

        onAccepted: {
            playlistModel.clear()
            window.currentIndex = -1
            player.stop()
        }

        contentItem: ColumnLayout {
            spacing: 12
            Label {
                text: qsTr("确定要清空播放列表吗？\n所有歌曲将被移除。")
                color: "black"
                font.pixelSize: 14
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }
    }
}
