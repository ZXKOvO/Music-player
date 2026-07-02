import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// 歌词面板：逐字高亮显示，点击某行可跳转，封面作为背景
Rectangle {
    id: root
    color: "#ffffff"

    // 封面背景图片（通过 ImageProvider 从内存加载，无临时文件）
    Image {
        id: coverBg
        anchors.fill: parent
        source: player.hasCover ? "image://cover/current" : ""
        fillMode: Image.PreserveAspectCrop
        visible: status === Image.Ready
        opacity: 1
        cache: false
        asynchronous: true
    }

    // 半透明遮罩，确保歌词可读
    Rectangle {
        anchors.fill: parent
        color: coverBg.visible ? "#99000000" : "#ffffff"
    }

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
                            color: (isActive && index <= activeChar) ? "#1db954" : (coverBg.visible ? "#cccccc" : "#666666")
                            font.pixelSize: isActive ? 18 : 14
                            font.bold: isActive && index <= activeChar
                        }
                    }
                }

                TapHandler {
                    enabled: !window.isAnyPopupOpen
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
            Layout.alignment: Qt.AlignCenter
            visible: player.lyrics.lineCount === 0
            color: coverBg.visible ? "#cccccc" : "#999999"
            font.pixelSize: 20
            text: player.title ? "暂无歌词" : "请播放歌曲"
        }
    }
}
