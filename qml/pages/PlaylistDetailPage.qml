import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// 歌单详情页：查看某个歌单内的歌曲，支持添加/移除/长按拖动排序
    ColumnLayout {
    id: root
    spacing: 8

    // 拖拽排序相关状态
    property int rowHeight: 40            // 单行歌曲高度
    property int rowStride: rowHeight + 2 // 行高 + 间距
    property int dragFromIndex: -1        // 正在拖动的歌曲原始索引，-1 表示未在拖动
    property bool dragging: false         // 是否处于拖动状态

    // 长按确认后开始拖动：显示浮动行并跟随鼠标
    function startSongDrag(fromIndex, songRow, pos) {
        if (dragging) return
        dragFromIndex = fromIndex
        dragging = true
        detailSongsView.interactive = false // 拖动期间禁止列表滚动抢走鼠标事件
        dragGhost.visible = true
        dropIndicator.visible = true
        dragGhost.y = Math.max(0, fromIndex * rowStride - detailSongsView.contentY)
        updateDragPosition(songRow, pos)
    }

    // 拖动中更新浮动行位置与落点指示线
    function updateDragPosition(songRow, pos) {
        if (!dragging) return
        var p = songRow.mapToItem(detailSongsView, pos.x, pos.y)
        dragGhost.y = Math.max(0, Math.min(p.y - rowHeight / 2, detailSongsView.height - rowHeight))
        var target = dragTargetIndex(p)
        dropIndicator.y = (target > dragFromIndex ? (target + 1) * rowStride - 2 : target * rowStride)
                          - detailSongsView.contentY
    }

    // 根据鼠标在列表视图内的位置计算目标落点索引
    function dragTargetIndex(p) {
        var count = window.detailSongCount
        if (count <= 0) return 0
        var t = Math.floor((p.y + detailSongsView.contentY) / rowStride)
        return Math.max(0, Math.min(t, count - 1))
    }

    // 松开鼠标：若在歌单详情页范围内则执行排序，超出范围则回到原位
    function finishSongDrag(songRow, pos, canceled) {
        if (!dragging) return
        detailSongsView.interactive = true
        var moved = false
        var p = songRow.mapToItem(root, pos.x, pos.y)
        var insidePage = p.x >= 0 && p.y >= 0 && p.x <= root.width && p.y <= root.height
        if (!canceled && insidePage && dragFromIndex >= 0) {
            var target = dragTargetIndex(songRow.mapToItem(detailSongsView, pos.x, pos.y))
            if (target !== dragFromIndex) {
                moved = playlistManager.moveSong(playlistManager.currentPlaylistIndex, dragFromIndex, target)
            }
        }
        dragGhost.visible = false
        dropIndicator.visible = false
        dragging = false
        dragFromIndex = -1
        if (moved) rebuildSongList()
    }

    // 排序后强制重建列表视图，使行顺序与歌单数据一致
    function rebuildSongList() {
        var m = window.detailSongCount
        detailSongsView.model = 0
        detailSongsView.model = m
        detailSongsView.model = Qt.binding(function() { return window.detailSongCount })
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 12
        Layout.topMargin: 8
        Button {
            flat: true
            implicitWidth: 32
            implicitHeight: 32
            onClicked: {
                window.leftView = "playlists"
                leftStackView.pop()
            }
            contentItem: Label {
                text: "\u2190"
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
        Label {
            text: playlistManager.currentPlaylistName
            color: "black"
            font.pixelSize: 18
            font.bold: true
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
        // 重命名歌单按钮：修改当前歌单名称
        Button {
            flat: true
            implicitWidth: 28
            implicitHeight: 28
            onClicked: window.openRenamePlaylistDialog(playlistManager.currentPlaylistIndex,
                                                       playlistManager.currentPlaylistName)
            contentItem: Label {
                text: "\u270E"
                color: "dimgray"
                font.pixelSize: 16
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: parent.hovered ? "honeydew" : "transparent"
                radius: 4
            }
        }
    }

    // Separator
    Rectangle {
        Layout.fillWidth: true
        Layout.leftMargin: 12
        Layout.rightMargin: 12
        Layout.preferredHeight: 1
        color: "lightgray"
    }

    // Song list
    ListView {
        id: detailSongsView
        objectName: "detailSongsView"
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 2

        model: window.detailSongCount

        // 拖动时的浮动歌曲行，跟随鼠标移动
        Rectangle {
            id: dragGhost
            visible: false
            z: 10
            width: detailSongsView.width
            height: rowHeight
            color: "white"
            border.color: "limegreen"
            border.width: 2
            radius: 4
            Label {
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 16
                text: playlistManager.songTitle(playlistManager.currentPlaylistIndex, root.dragFromIndex)
                color: "black"
                font.pixelSize: 14
                elide: Text.ElideRight
            }
        }

        // 落点指示线
        Rectangle {
            id: dropIndicator
            visible: false
            z: 9
            width: detailSongsView.width
            height: 2
            color: "limegreen"
        }

        delegate: Rectangle {
            objectName: "songRowDelegate"
            width: detailSongsView.width
            height: rowHeight
            color: ListView.isCurrentItem ? "lightgray" : (dtHover.hovered ? "whitesmoke" : "transparent")
            opacity: root.dragging && root.dragFromIndex === index ? 0.4 : 1.0

            property int songIndex: index
            property string songPath: playlistManager.songFilePath(playlistManager.currentPlaylistIndex, index)
            property string songName: {
                // 依赖版本号：歌单内标题修改后触发重新读取
                var _v = window.playlistSongVersion
                return playlistManager.songTitle(playlistManager.currentPlaylistIndex, index)
            }

            // 双击歌曲：添加到播放列表（如不存在）并播放，使用歌单内保存的标题
            function playSong() {
                if (!playlistModel.contains(songPath)) {
                    playlistModel.addFile(songPath)
                }
                // 查找已添加歌曲的索引
                window.currentIndex = playlistModel.count - 1
                for (var i = 0; i < playlistModel.count; i++) {
                    if (playlistModel.filePath(i) === songPath) {
                        window.currentIndex = i
                        break
                    }
                }
                // 同步队列显示标题（歌单内可能已自定义修改过）
                playlistModel.setTitle(window.currentIndex, songName)
                player.playFileWithMeta(songPath, songName, "")
            }

            // 长按（600ms）进入拖动排序：拖动中跟随时松开落位；
            // 若松开时鼠标已超出歌单详情页范围，则歌曲回到原位。
            Item {
                id: songDragArea
                anchors.fill: parent
                anchors.rightMargin: 80 // 排除右侧重命名/移除按钮区域，避免影响按钮点击

Timer {
                id: songHoldTimer
                interval: 600
                onTriggered: {
                    if (songDragHandler.pressed && !root.dragging) {
                        root.startSongDrag(songIndex, songDragArea, songDragHandler.point.position)
                    }
                }
            }

            TapHandler {
                id: songDragHandler
                acceptedButtons: Qt.LeftButton
                // 仅作事件源；dragThreshold 足够大，移动不会被判定为越界取消手势
                dragThreshold: 30000
                gesturePolicy: TapHandler.ReleaseWithinBounds
                onPressedChanged: {
                    if (pressed) {
                            // 按下即禁用列表滚动，确保后续移动事件不会被 Flickable 抢走
                            detailSongsView.interactive = false
                            songHoldTimer.start()
                        } else {
                            songHoldTimer.stop()
                            if (root.dragging) {
                                // 松开（或手势被取消）时结束拖动：位置由 finishSongDrag 判定
                                root.finishSongDrag(songDragArea, point.position)
                            } else {
                                detailSongsView.interactive = true
                            }
                        }
                    }
                    onPointChanged: {
                        if (root.dragging) root.updateDragPosition(songDragArea, point.position)
                    }
                    onDoubleTapped: (eventPoint, button) => {
                        playSong()
                    }
                }
            }

            HoverHandler {
                id: dtHover
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
                    text: songName
                    color: "black"
                    font.pixelSize: 14
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Button {
                    flat: true
                    implicitWidth: 28
                    implicitHeight: 28
                    visible: dtHover.hovered
                    onClicked: renameSongDialog.openWithIndex(songIndex)
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
                    visible: dtHover.hovered
                    onClicked: removeSongConfirmDialog.openWithIndex(songIndex)
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

        Label {
            anchors.centerIn: parent
            visible: window.detailSongCount === 0
            text: qsTr("暂无歌曲")
            color: "gray"
            font.pixelSize: 14
        }

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }
    }

    // Action buttons
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 8
        Layout.rightMargin: 8
        spacing: 8

        Button {
            text: qsTr("+ 从列表添加")
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            flat: true
            onClicked: addToPlaylistPopup.open()
            contentItem: Label {
                text: qsTr("+ 从列表添加")
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

        Button {
            text: qsTr("+ 从文件导入")
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            flat: true
            onClicked: window.openImportFileDialog()
            contentItem: Label {
                text: qsTr("+ 从文件导入")
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

    // 编辑歌曲标题对话框：只修改歌单内显示标题并保存到 JSON，不改音频文件
    Dialog {
        id: renameSongDialog
        title: qsTr("编辑歌曲标题")
        anchors.centerIn: parent
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel
        width: 340
        onOpened: {
            window.isAnyPopupOpen = true
            songTitleInput.forceActiveFocus()
            songTitleInput.selectAll()
        }
        onClosed: window.isAnyPopupOpen = false
        onAccepted: applySongTitle()
        onRejected: targetIndex = -1

        property int targetIndex: -1

        function openWithIndex(idx) {
            targetIndex = idx
            songTitleInput.text = playlistManager.songTitle(playlistManager.currentPlaylistIndex, idx)
            open()
        }

        // 应用修改：更新歌单 JSON，并同步播放队列与正在播放歌曲的显示
        function applySongTitle() {
            if (targetIndex < 0) return
            var newTitle = songTitleInput.text.trim()
            var plIdx = playlistManager.currentPlaylistIndex
            if (newTitle.length === 0) { targetIndex = -1; return }
            if (playlistManager.setSongTitle(plIdx, targetIndex, newTitle)) {
                var path = playlistManager.songFilePath(plIdx, targetIndex)
                var queueIdx = playlistModel.indexOf(path)
                if (queueIdx >= 0) {
                    playlistModel.setTitle(queueIdx, newTitle)
                    if (queueIdx === window.currentIndex) {
                        player.setTitleArtistOverride(newTitle, player.artist)
                    }
                }
                window.showToast(qsTr("已修改标题"))
            }
            targetIndex = -1
        }

        background: Rectangle {
            color: "white"
            radius: 8
        }

        header: Rectangle {
            color: "white"
            implicitHeight: 44
            radius: 8
            Label {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("编辑歌曲标题")
                color: "black"
                font.pixelSize: 16
                font.bold: true
            }
        }

        contentItem: ColumnLayout {
            spacing: 12
            Label {
                text: qsTr("请输入新的歌曲标题（仅保存到歌单，不改原文件）：")
                color: "black"
                font.pixelSize: 13
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            TextField {
                id: songTitleInput
                Layout.fillWidth: true
                maximumLength: 60
                onAccepted: renameSongDialog.accept()
            }
        }
    }

    // Remove song confirmation dialog
    ConfirmDialog {
        id: removeSongConfirmDialog
        title: qsTr("移除歌曲")

        property int targetIndex: -1

        function openWithIndex(idx) {
            targetIndex = idx
            open()
        }

        onAccepted: {
            if (targetIndex >= 0) {
                playlistManager.removeSongFromCurrentPlaylist(targetIndex)
                targetIndex = -1
            }
        }
        onRejected: targetIndex = -1

        contentItem: ColumnLayout {
            spacing: 12
            Label {
                text: qsTr("确定要从歌单中移除这首歌曲吗？")
                color: "black"
                font.pixelSize: 14
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }
    }
}
