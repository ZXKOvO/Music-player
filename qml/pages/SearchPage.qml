import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// 在线歌曲搜索页面
ColumnLayout {
    id: root
    spacing: 0

    // 搜索栏：输入关键词，点击搜索或按回车触发搜索
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 52
        color: "whitesmoke"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.topMargin: 8
            anchors.bottomMargin: 8
            spacing: 8

            // 搜索输入框
            TextField {
                id: searchField
                Layout.fillWidth: true
                Layout.fillHeight: true
                placeholderText: qsTr("搜索歌曲、歌手...")
                font.pixelSize: 14
                color: "black"
                background: Rectangle {
                    color: "white"
                    radius: 4
                    border.color: searchField.activeFocus ? "limegreen" : "lightgray"
                    border.width: 1
                }
                onAccepted: songSearcher.search(text)  // 按回车触发搜索
            }

            // 搜索按钮
            Button {
                text: qsTr("搜索")
                Layout.fillHeight: true
                Layout.preferredWidth: 64
                enabled: !songSearcher.searching && searchField.text.trim().length > 0
                onClicked: songSearcher.search(searchField.text)
                contentItem: Label {
                    text: qsTr("搜索")
                    color: parent.enabled ? "white" : "lightgray"
                    font.pixelSize: 14
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: parent.enabled ? "limegreen" : "lightgray"
                    radius: 4
                }
            }
        }
    }

    // 分隔线
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: "lightgray"
    }

    // 搜索状态指示器：显示"搜索中..."或错误信息
    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 36
        Layout.leftMargin: 12
        Layout.rightMargin: 12
        visible: songSearcher.searching || songSearcher.errorMessage.length > 0

        Label {
            text: songSearcher.searching ? qsTr("搜索中...") : songSearcher.errorMessage
            color: songSearcher.errorMessage.length > 0 ? "red" : "gray"
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

    // 搜索结果列表
    ListView {
        id: resultView
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        model: songSearcher.model  // 绑定搜索结果模型
        spacing: 0

        // 每行歌曲条目
        delegate: Rectangle {
            width: resultView.width
            height: 56
            color: resultHover.hovered ? "whitesmoke" : "transparent"

            property int songDuration: duration  // 歌曲时长（秒）

            HoverHandler {
                id: resultHover
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 12

                // 序号
                Label {
                    text: (index + 1)
                    color: "gray"
                    font.pixelSize: 13
                    Layout.preferredWidth: 28
                    horizontalAlignment: Text.AlignRight
                }

                // 歌曲信息列：歌名 + 艺术家 · 专辑 · 时长
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    // 歌曲名
                    Label {
                        text: name || ""
                        color: "black"
                        font.pixelSize: 14
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    // 歌手、专辑、时长（用 · 分隔）
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
                        color: "gray"
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                // 播放按钮（悬停时显示）
                Button {
                    flat: true
                    implicitWidth: 32
                    implicitHeight: 32
                    visible: resultHover.hovered
                    onClicked: {
                        songSearcher.pendingPlay = true  // 标记为播放模式
                        window.showToast(qsTr("正在获取歌曲..."))
                        songSearcher.getSongUrl(songId, name, artist)
                    }
                    contentItem: Label {
                        text: "\u25B6"  // 播放图标
                        color: "limegreen"
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: parent.hovered ? "honeydew" : "transparent"
                        radius: 4
                    }
                }

                // 添加到播放列表按钮（悬停时显示）
                Button {
                    flat: true
                    implicitWidth: 32
                    implicitHeight: 32
                    visible: resultHover.hovered
                    onClicked: {
                        songSearcher.pendingPlay = false  // 标记为添加模式
                        window.showToast(qsTr("正在获取歌曲..."))
                        songSearcher.getSongUrl(songId, name, artist)
                    }
                    contentItem: Label {
                        text: "+"  // 添加图标
                        color: "limegreen"
                        font.pixelSize: 18
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: parent.hovered ? "honeydew" : "transparent"
                        radius: 4
                    }
                }
            }
        }

        // 空状态提示：无搜索结果时显示
        Label {
            anchors.centerIn: parent
            visible: songSearcher.model.count === 0 && !songSearcher.searching
            text: qsTr("搜索在线歌曲")
            color: "gray"
            font.pixelSize: 15
        }

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }
    }
}
