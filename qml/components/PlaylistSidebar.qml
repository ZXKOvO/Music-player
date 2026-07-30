import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// 播放列表侧边栏：从右侧滑出，显示当前播放队列
Rectangle {
    id: root
    property bool isOpen: false
    property int controlBarHeight: 0
    width: Math.max(200, Math.min(320, window.width * 0.28))
    height: parent.height - controlBarHeight - 12
    y: 6
    color: "white"
    z: 100
    clip: true
    x: isOpen ? parent.width - width : parent.width

    // 滑入/滑出动画：200ms 缓出效果
    Behavior on x {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    // 自动隐藏定时器：鼠标移出播放列表 300ms 后自动关闭
    Timer {
        id: closeTimer
        interval: 300
        onTriggered: root.isOpen = false
    }

    // 鼠标悬停处理：悬停在播放列表上时保持打开，移出时自动关闭
    HoverHandler {
        onHoveredChanged: {
            if (hovered) {
                closeTimer.stop()
                root.isOpen = true
            } else {
                closeTimer.restart()
            }
        }
    }

    // 左侧分割线
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 20
        color: "lightgray"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 1
        spacing: 0

        // Header
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            color: "whitesmoke"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 8
                spacing: 6

                Label {
                    text: qsTr("播放列表")
                    color: "black"
                    font.pixelSize: 13
                    font.bold: true
                }
                Rectangle {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 16
                    radius: 8
                    color: "whitesmoke"
                    Label {
                        anchors.centerIn: parent
                        text: playlistModel.count
                        color: "dimgray"
                        font.pixelSize: 10
                    }
                }
                Item { Layout.fillWidth: true }
                Button {
                    flat: true
                    implicitWidth: 28
                    implicitHeight: 28
                    onClicked: root.isOpen = false
                    contentItem: Label {
                        text: "\u2715"
                        color: "gray"
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: parent.hovered ? "lightgray" : "transparent"
                        radius: 4
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: "lightgray"
        }

        // Song list
        ListView {
            id: songListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: playlistModel
            currentIndex: window.currentIndex
            spacing: 0

            delegate: Rectangle {
                width: songListView.width
                height: 36
                color: ListView.isCurrentItem ? "honeydew" : (sidebarHover.hovered ? "whitesmoke" : "transparent")

                TapHandler {
                    // 双击歌曲条目：设置为当前播放并开始播放
                    onDoubleTapped: {
                        window.currentIndex = index
                        player.playFile(filePath)
                    }
                }

                HoverHandler {
                    id: sidebarHover
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 8
                    spacing: 10

                    Label {
                        text: (index + 1)
                        color: ListView.isCurrentItem ? "limegreen" : "gray"
                        font.pixelSize: 12
                        Layout.preferredWidth: 24
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
                        color: ListView.isCurrentItem ? "limegreen" : "dimgray"
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Label {
                        text: {
                            var d = duration || 0
                            var m = Math.floor(d / 60)
                            var s = Math.floor(d % 60)
                            return m + ":" + (s < 10 ? "0" : "") + s
                        }
                        color: "gray"
                        font.pixelSize: 11
                    }

                    Button {
                        flat: true
                        implicitWidth: 24
                        implicitHeight: 24
                        visible: sidebarHover.hovered
                        onClicked: {
                            playlistModel.remove(index)
                            if (index === window.currentIndex) {
                                player.stop()
                                window.currentIndex = -1
                            } else if (index < window.currentIndex) {
                                window.currentIndex--
                            }
                        }
                        contentItem: Label {
                            text: "\u2715"
                            color: "red"
                            font.pixelSize: 11
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
                    visible: index < playlistModel.count - 1
                }
            }

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            Label {
                anchors.centerIn: parent
                visible: playlistModel.count === 0
                text: qsTr("播放列表为空，请先添加歌曲")
                color: "gray"
                font.pixelSize: 13
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: "lightgray"
            visible: playlistModel.count > 0
        }

        Button {
            text: qsTr("清空播放列表")
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            visible: playlistModel.count > 0
            flat: true
            contentItem: Label {
                text: qsTr("清空播放列表")
                color: "gray"
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: parent.hovered ? "whitesmoke" : "transparent"
            }
            onClicked: {
                playlistModel.clear()
                window.currentIndex = -1
                player.stop()
            }
        }
    }
}
