import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// 歌词面板：逐字高亮显示，点击某行可跳转
Rectangle {
    id: root
    color: "#ffffff"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 0

        ListView {
            id: lyricsView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: player.lyrics.lineCount
            highlightFollowsCurrentItem: false

            property int activeIndex: player.lyrics.lineAt(player.position)

            delegate: Item {
                width: lyricsView.width
                height: 36

                property int lineIdx: index
                property int activeLine: lyricsView.activeIndex
                property bool isActive: lineIdx === activeLine
                property int activeChar: isActive ? player.lyrics.charIndexAt(player.position, activeLine) : -1

                Row {
                    anchors.centerIn: parent
                    spacing: 0

                    Repeater {
                        model: player.lyrics.textAt(lineIdx) || ""

                        Label {
                            text: modelData
                            color: (isActive && index <= activeChar) ? "#1db954" : "#666666"
                            font.pixelSize: isActive ? 18 : 14
                            font.bold: isActive && index <= activeChar
                        }
                    }
                }

                TapHandler {
                    cursorShape: Qt.PointingHandCursor
                    onTapped: player.seek(player.lyrics.timeAt(lineIdx))
                }
            }

            onActiveIndexChanged: {
                if (activeIndex >= 0) {
                    positionViewAtIndex(activeIndex, ListView.Center)
                }
            }
        }

        Label {
            anchors.centerIn: parent
            visible: player.lyrics.lineCount === 0
            color: "#999999"
            font.pixelSize: 20
            text: player.title ? "暂无歌词" : "请播放歌曲"
        }
    }
}
