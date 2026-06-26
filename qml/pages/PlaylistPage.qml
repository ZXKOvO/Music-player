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
            color: "#000000"
            font.pixelSize: 18
            font.bold: true
        }
        Label {
            text: playlistModel.count
            color: "#666666"
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
            color: ListView.isCurrentItem ? "#e8e8e8" : (hoverHandler.hovered ? "#f0f0f0" : "transparent")

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
                    color: "#666666"
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
                    color: "#000000"
                    font.pixelSize: 14
                    elide: Text.ElideRight
                    Layout.fillWidth: true
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
            color: "#888888"
            font.pixelSize: 14
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            color: parent.hovered ? "#e8e8e8" : "transparent"
            radius: 4
        }
        onClicked: {
            playlistModel.clear()
            window.currentIndex = -1
            player.stop()
        }
    }
}
