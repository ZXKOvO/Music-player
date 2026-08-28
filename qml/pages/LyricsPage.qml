import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// 歌词面板：逐字高亮显示，点击某行可跳转，封面作为背景
Rectangle {
    id: root
    color: "white"

    // 当前行歌词字号（由主窗口统一管理，右上角 Aa 按钮可调节并持久化保存）
    property int lyricFontSize: window.lyricFontSize
    readonly property int minFontSize: window.minLyricFontSize
    readonly property int maxFontSize: window.maxLyricFontSize
    readonly property int inactiveFontSize: Math.max(8, lyricFontSize - 4)
    readonly property int lineHeight: lyricFontSize * 2.2

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
        color: coverBg.visible ? Qt.rgba(0, 0, 0, 0.6) : "white"
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
                height: root.lineHeight

                property int lineIdx: index
                property int activeLine: lyricsView.activeIndex
                property bool isActive: lineIdx === activeLine
                property int activeChar: isActive ? player.lyrics.charIndexAt(player.position, activeLine) : -1

                Row {
                    anchors.centerIn: parent
                    spacing: 0

                    // 仅点击歌词文字本身才跳转，点击背景不触发
                    TapHandler {
                        enabled: !window.isAnyPopupOpen
                        cursorShape: Qt.PointingHandCursor
                        onTapped: player.seek(player.lyrics.timeAt(lineIdx))
                    }

                    Repeater {
                        model: player.lyrics.textAt(lineIdx) || ""

                        Label {
                            text: modelData
                            color: (isActive && index <= activeChar) ? "limegreen" : (coverBg.visible ? "lightgray" : "dimgray")
                            font.pixelSize: isActive ? root.lyricFontSize : root.inactiveFontSize
                            font.bold: isActive && index <= activeChar
                        }
                    }
                }
            }

            // 当前行变化时自动滚动到居中位置
            onActiveIndexChanged: {
                if (activeIndex >= 0) {
                    positionViewAtIndex(activeIndex, ListView.Center)
                }
            }
        }
    }

    // 歌词字号调节入口（右上角悬浮按钮）
    Button {
        id: fontSizeBtn
        z: 10
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 10
        width: 32
        height: 32
        flat: true
        onClicked: fontSizePopup.open()
        contentItem: Label {
            text: "Aa"
            color: coverBg.visible ? "white" : "dimgray"
            font.pixelSize: 15
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            radius: 16
            border.color: "gray"
            border.width: 1
            color: fontSizeBtn.hovered || fontSizePopup.opened
                   ? (coverBg.visible ? Qt.rgba(0, 0, 0, 0.45) : Qt.rgba(0, 0, 0, 0.08))
                   : "transparent"
        }
        ToolTip.text: qsTr("调节歌词字号")
        ToolTip.visible: fontSizeBtn.hovered && !fontSizePopup.opened
    }

    // 字号调节弹窗：A- / A+ 按钮 + 滑块
    Popup {
        id: fontSizePopup
        x: fontSizeBtn.x + fontSizeBtn.width - width
        y: fontSizeBtn.y + fontSizeBtn.height + 6
        width: 210
        padding: 12
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onOpened: window.isAnyPopupOpen = true
        onClosed: window.isAnyPopupOpen = false

        background: Rectangle {
            radius: 10
            color: Qt.rgba(0.09, 0.09, 0.09, 0.95)
            border.color: "dimgray"
            border.width: 1
        }

        contentItem: ColumnLayout {
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                // 减小字号
                Button {
                    id: fontDecBtn
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 30
                    flat: true
                    enabled: window.lyricFontSize > root.minFontSize
                    onClicked: window.lyricFontSize = Math.max(root.minFontSize, window.lyricFontSize - 1)
                    contentItem: Label {
                        text: "-"
                        color: fontDecBtn.enabled ? "white" : "gray"
                        font.pixelSize: 20
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius: 6
                        border.color: "gray"
                        border.width: 1
                        color: fontDecBtn.hovered && fontDecBtn.enabled ? "dimgray" : "transparent"
                    }
                    ToolTip.text: qsTr("减小歌词字号")
                    ToolTip.visible: fontDecBtn.hovered
                }

                // 当前字号
                Label {
                    Layout.fillWidth: true
                    text: window.lyricFontSize
                    color: "white"
                    font.pixelSize: 16
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                // 增大字号
                Button {
                    id: fontIncBtn
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 30
                    flat: true
                    enabled: window.lyricFontSize < root.maxFontSize
                    onClicked: window.lyricFontSize = Math.min(root.maxFontSize, window.lyricFontSize + 1)
                    contentItem: Label {
                        text: "+"
                        color: fontIncBtn.enabled ? "white" : "gray"
                        font.pixelSize: 20
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius: 6
                        border.color: "gray"
                        border.width: 1
                        color: fontIncBtn.hovered && fontIncBtn.enabled ? "dimgray" : "transparent"
                    }
                    ToolTip.text: qsTr("增大歌词字号")
                    ToolTip.visible: fontIncBtn.hovered
                }
            }

            // 精细调节滑块
            Slider {
                id: sizeSlider
                Layout.fillWidth: true
                from: root.minFontSize
                to: root.maxFontSize
                stepSize: 1
                live: true
                value: window.lyricFontSize
                onMoved: window.lyricFontSize = value

                background: Rectangle {
                    x: sizeSlider.leftPadding
                    y: sizeSlider.topPadding + sizeSlider.availableHeight / 2 - height / 2
                    implicitHeight: 4
                    width: sizeSlider.availableWidth
                    height: implicitHeight
                    radius: 2
                    color: "gray"

                    Rectangle {
                        width: sizeSlider.visualPosition * parent.width
                        height: parent.height
                        color: "limegreen"
                        radius: 2
                    }
                }

                handle: Rectangle {
                    x: sizeSlider.leftPadding + sizeSlider.visualPosition * (sizeSlider.availableWidth - width)
                    y: sizeSlider.topPadding + sizeSlider.availableHeight / 2 - height / 2
                    implicitWidth: 14
                    implicitHeight: 14
                    radius: 7
                    color: sizeSlider.pressed ? "limegreen" : "white"
                }
            }
        }
    }

    Label {
        anchors.centerIn: parent
        visible: player.lyrics.lineCount === 0
        color: coverBg.visible ? "lightgray" : "gray"
        font.pixelSize: 20
        text: player.title ? "暂无歌词" : "请播放歌曲"
    }
}
