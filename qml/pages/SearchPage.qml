import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// 在线歌曲搜索页面
ColumnLayout {
    id: root
    spacing: 0

    // Search bar
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 52
        color: "#f5f5f5"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.topMargin: 8
            anchors.bottomMargin: 8
            spacing: 8

            TextField {
                id: searchField
                Layout.fillWidth: true
                Layout.fillHeight: true
                placeholderText: qsTr("搜索歌曲、歌手...")
                font.pixelSize: 14
                color: "#000000"
                background: Rectangle {
                    color: "#ffffff"
                    radius: 4
                    border.color: searchField.activeFocus ? "#1db954" : "#e0e0e0"
                    border.width: 1
                }
                onAccepted: songSearcher.search(text)
            }

            Button {
                text: qsTr("搜索")
                Layout.fillHeight: true
                Layout.preferredWidth: 64
                enabled: !songSearcher.searching && searchField.text.trim().length > 0
                onClicked: songSearcher.search(searchField.text)
                contentItem: Label {
                    text: qsTr("搜索")
                    color: parent.enabled ? "#ffffff" : "#cccccc"
                    font.pixelSize: 14
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: parent.enabled ? "#1db954" : "#cccccc"
                    radius: 4
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: "#e0e0e0"
    }

    // Search status indicator
    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 36
        Layout.leftMargin: 12
        Layout.rightMargin: 12
        visible: songSearcher.searching || songSearcher.errorMessage.length > 0

        Label {
            text: songSearcher.searching ? qsTr("搜索中...") : songSearcher.errorMessage
            color: songSearcher.errorMessage.length > 0 ? "#cc0000" : "#888888"
            font.pixelSize: 13
            Layout.fillWidth: true
        }

        BusyIndicator {
            running: songSearcher.searching
            visible: songSearcher.searching
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
        }
    }

    // Search results list
    ListView {
        id: resultView
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        model: songSearcher.model
        spacing: 0

        delegate: Rectangle {
            width: resultView.width
            height: 56
            color: resultHover.hovered ? "#f0f0f0" : "transparent"

            property int songDuration: duration

            HoverHandler {
                id: resultHover
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 12

                // Index number
                Label {
                    text: (index + 1)
                    color: "#999999"
                    font.pixelSize: 13
                    Layout.preferredWidth: 28
                    horizontalAlignment: Text.AlignRight
                }

                // Song info column
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Label {
                        text: name || ""
                        color: "#000000"
                        font.pixelSize: 14
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Label {
                        text: {
                            var parts = []
                            if (artist) parts.push(artist)
                            if (album) parts.push(album)
                            var durMin = Math.floor(songDuration / 60)
                            var durSec = songDuration % 60
                            parts.push(durMin + ":" + (durSec < 10 ? "0" : "") + durSec)
                            return parts.join(" \u00B7 ")
                        }
                        color: "#888888"
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                // Play button (visible on hover)
                Button {
                    flat: true
                    implicitWidth: 32
                    implicitHeight: 32
                    visible: resultHover.hovered
                    onClicked: {
                        window.showToast(qsTr("播放功能暂未实现"))
                    }
                    contentItem: Label {
                        text: "\u25B6"
                        color: "#1db954"
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: parent.hovered ? "#e8f5e9" : "transparent"
                        radius: 4
                    }
                }

                // Add to playlist button (visible on hover)
                Button {
                    flat: true
                    implicitWidth: 32
                    implicitHeight: 32
                    visible: resultHover.hovered
                    onClicked: {
                        window.showToast(qsTr("添加功能暂未实现"))
                    }
                    contentItem: Label {
                        text: "+"
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
            }
        }

        // Empty state label
        Label {
            anchors.centerIn: parent
            visible: songSearcher.model.count === 0 && !songSearcher.searching
            text: qsTr("搜索在线歌曲")
            color: "#999999"
            font.pixelSize: 15
        }

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }
    }
}
