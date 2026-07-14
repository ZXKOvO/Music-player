import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Window
import MusicPlayer

ApplicationWindow {
    id: window
    width: 1000
    height: 500
    visible: true
    title: qsTr("Music Player")
    color: "#2b2b2b"

    property int currentIndex: -1
    property string leftView: "search"
    property int detailSongCount: 0
    property int playlistSongVersion: 0
    property bool isAnyPopupOpen: false

    PlaylistModel { id: playlistModel }

    PlaylistManager {
        id: playlistManager
        onSongsChanged: {
            playlistSongVersion++
            if (currentPlaylistIndex >= 0) {
                detailSongCount = playlistSongCount(currentPlaylistIndex)
            } else {
                detailSongCount = 0
            }
        }
        onCurrentPlaylistIndexChanged: {
            if (currentPlaylistIndex >= 0) {
                detailSongCount = playlistSongCount(currentPlaylistIndex)
            } else {
                detailSongCount = 0
            }
        }
    }

    PlayerController {
        id: player
        onPlaybackFinished: autoPlayNext()
        Component.onCompleted: registerCoverProvider()
        onShowDesktopLyricsChanged: {
            if (showDesktopLyrics) {
                ensureDesktopLyricsWindow().visible = true
            } else {
                if (desktopLyricsObj) desktopLyricsObj.visible = false
            }
        }
    }

    property var desktopLyricsObj: null

    function ensureDesktopLyricsWindow() {
        if (!desktopLyricsObj) {
            desktopLyricsObj = desktopLyricsComponent.createObject(null)
        }
        return desktopLyricsObj
    }

    Component {
        id: desktopLyricsComponent
        Window {
            id: desktopLyricsWindow
            width: 500
            height: 100
            visible: true
            title: qsTr("桌面歌词")
            color: "transparent"
            flags: Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint
            x: (Screen.width - width) / 2
            y: Screen.height - height - 100

            property int activeIndex: player.lyrics.lineAt(player.position)
            property int nextIndex: activeIndex + 1 < player.lyrics.lineCount ? activeIndex + 1 : -1

            Rectangle {
                anchors.fill: parent
                color: "#cc1a1a1a"
                radius: 10

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 1
                    spacing: 0

                    // 歌词区域
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Column {
                            anchors.centerIn: parent
                            spacing: 4

                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 0

                                Repeater {
                                    model: player.lyrics.textAt(activeIndex) || ""

                                    Label {
                                        text: modelData
                                        color: index <= player.lyrics.charIndexAt(player.position, activeIndex)
                                               ? "#1db954" : "#cccccc"
                                        font.pixelSize: 20
                                        font.bold: index <= player.lyrics.charIndexAt(player.position, activeIndex)
                                    }
                                }
                            }

                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 0
                                visible: nextIndex >= 0

                                Repeater {
                                    model: player.lyrics.textAt(nextIndex) || ""

                                    Label {
                                        text: modelData
                                        color: "#888888"
                                        font.pixelSize: 14
                                    }
                                }
                            }
                        }

                        Label {
                            anchors.centerIn: parent
                            visible: player.lyrics.lineCount === 0
                            color: "#999999"
                            font.pixelSize: 16
                            text: player.title ? "暂无歌词" : "请播放歌曲"
                        }

                        // 关闭按钮（右上角）
                        Button {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 4
                            width: 20
                            height: 20
                            flat: true
                            z: 2
                            onClicked: player.showDesktopLyrics = false
                            contentItem: Label {
                                text: "\u2715"
                                color: "#999999"
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                color: parent.hovered ? "#444444" : "transparent"
                                radius: 10
                            }
                        }
                    }

                    // 分割线
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.leftMargin: 10
                        Layout.rightMargin: 10
                        Layout.preferredHeight: 1
                        color: "#555555"
                    }

                    // 控制栏：上一首 / 播放暂停 / 下一首（居中）
                    Row {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        layoutDirection: Qt.RightToLeft
                        spacing: 0

                        Item { width: (parent.width - 112) / 2; height: 1 }

                        // 下一首
                        Button {
                            width: 36
                            height: 30
                            flat: true
                            onClicked: window.playNext()
                            contentItem: Label {
                                text: "\u23ED"
                                color: "#aaaaaa"
                                font.pixelSize: 14
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                color: parent.hovered ? "#444444" : "transparent"
                                radius: 4
                            }
                        }

                        // 播放/暂停
                        Button {
                            width: 40
                            height: 30
                            flat: true
                            onClicked: player.togglePlay()
                            contentItem: Label {
                                text: player.playing ? "\u23F8" : "\u25B6"
                                color: "#1db954"
                                font.pixelSize: 18
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                color: parent.hovered ? "#444444" : "transparent"
                                radius: 4
                            }
                        }

                        // 上一首
                        Button {
                            width: 36
                            height: 30
                            flat: true
                            onClicked: window.playPrevious()
                            contentItem: Label {
                                text: "\u23EE"
                                color: "#aaaaaa"
                                font.pixelSize: 14
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                color: parent.hovered ? "#444444" : "transparent"
                                radius: 4
                            }
                        }
                    }
                }
            }

            TapHandler {
                acceptedButtons: Qt.LeftButton
                onPressedChanged: {
                    if (pressed) {
                        player.startWindowSystemMove(desktopLyricsWindow)
                    }
                }
            }
        }
    }

    // 在线歌曲搜索器：处理搜索、下载、播放逻辑
    SongSearcher {
        id: songSearcher

        // 歌曲下载完成回调
        onSongUrlReady: function(filePath, songName, artist) {
            // 如果播放列表中没有此歌曲，则添加
            if (!playlistModel.contains(filePath)) {
                playlistModel.addFile(filePath)
            }
            // 如果是播放模式，自动播放该歌曲
            if (pendingPlay) {
                pendingPlay = false
                var idx = playlistModel.indexOf(filePath)
                if (idx >= 0) {
                    window.currentIndex = idx
                    player.playFile(filePath)
                }
            }
            window.showToast(qsTr("已添加: %1").arg(songName))
        }

        // 歌曲下载失败回调
        onSongUrlFailed: function(songName, reason) {
            window.showToast(qsTr("获取歌曲失败: %1").arg(reason))
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Top area: left panel + lyrics side by side
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // Left: Search + My playlists (no playlist tab)
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 350
                color: "#ffffff"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Navigation tabs
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        color: "#f5f5f5"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 4

                            Button {
                                text: qsTr("搜索")
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                flat: true
                                onClicked: {
                                    window.leftView = "search"
                                    leftStackView.pop(null)
                                    leftStackView.push(searchViewComp)
                                }
                                contentItem: Label {
                                    text: qsTr("搜索")
                                    color: window.leftView === "search" ? "#1db954" : "#666666"
                                    font.pixelSize: 14
                                    font.bold: window.leftView === "search"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                background: Rectangle {
                                    color: "transparent"
                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        width: parent.width
                                        height: 2
                                        color: "#1db954"
                                        visible: window.leftView === "search"
                                    }
                                }
                            }

                            Button {
                                text: qsTr("我的歌单")
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                flat: true
                                onClicked: {
                                    window.leftView = "playlists"
                                    leftStackView.pop(null)
                                    leftStackView.push(playlistsViewComp)
                                }
                                contentItem: Label {
                                    text: qsTr("我的歌单")
                                    color: window.leftView === "playlists" ? "#1db954" : "#666666"
                                    font.pixelSize: 14
                                    font.bold: window.leftView === "playlists"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                background: Rectangle {
                                    color: "transparent"
                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        width: parent.width
                                        height: 2
                                        color: "#1db954"
                                        visible: window.leftView === "playlists"
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: "#e0e0e0"
                    }

                    // Content area: StackView
                    StackView {
                        id: leftStackView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        initialItem: searchViewComp
                    }
                }
            }

            // Divider line
            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                color: "#cccccc"
            }

            // Right: Lyrics area
            LyricsPage {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }

        ControlBar {
            id: controlBar
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(48, window.height * 0.11)
        }
    }

    // ===== Page Components =====

    Component {
        id: playlistsViewComp
        PlaylistsPage {}
    }

    Component {
        id: searchViewComp
        SearchPage {}
    }

    Component {
        id: playlistDetailComp
        PlaylistDetailPage {}
    }

    // ===== Dialogs & Popups =====

    FileDialog {
        id: fileDialog
        title: qsTr("Select Audio File")
        fileMode: FileDialog.OpenFiles
        nameFilters: ["Audio Files (*.mp3 *.flac *.wav *.ogg *.aac *.ape)", "All Files (*)"]
        onAccepted: {
            var paths = selectedFiles
            for (var i = 0; i < paths.length; i++) {
                var path = paths[i].toString()
                if (!playlistModel.contains(path)) {
                    playlistModel.addFile(path)
                }
            }
            if (window.currentIndex === -1 && playlistModel.count > 0) {
                window.currentIndex = 0
                player.playFile(playlistModel.filePath(0))
            }
        }
    }

    Dialog {
        id: createPlaylistDialog
        title: qsTr("新建歌单")
        anchors.centerIn: parent
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel
        width: 320
        onOpened: { playlistNameInput.text = ""; window.isAnyPopupOpen = true }
        onClosed: window.isAnyPopupOpen = false
        onAccepted: {
            var name = playlistNameInput.text.trim()
            if (name.length > 0) {
                playlistManager.createPlaylist(name)
            }
        }
        contentItem: ColumnLayout {
            spacing: 12
            Label {
                text: qsTr("请输入歌单名称：")
                color: "#000000"
                font.pixelSize: 14
            }
            TextField {
                id: playlistNameInput
                Layout.fillWidth: true
                placeholderText: qsTr("歌单名称")
                maximumLength: 30
                onAccepted: createPlaylistDialog.accept()
            }
        }
    }

    // Add to playlist popup
    Popup {
        id: addToPlaylistPopup
        anchors.centerIn: parent
        width: 360
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onOpened: window.isAnyPopupOpen = true
        onClosed: window.isAnyPopupOpen = false

        background: Rectangle {
            color: "#ffffff"
            radius: 8
            border.color: "#e0e0e0"
            border.width: 1
        }

        contentItem: ColumnLayout {
            id: addToPlaylistColumn
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                Layout.topMargin: 12
                Layout.bottomMargin: 8
                Label {
                    text: qsTr("添加歌曲到：") + playlistManager.currentPlaylistName
                    color: "#000000"
                    font.pixelSize: 15
                    font.bold: true
                    Layout.fillWidth: true
                }
                Button {
                    flat: true
                    implicitWidth: 24
                    implicitHeight: 24
                    onClicked: addToPlaylistPopup.close()
                    contentItem: Label {
                        text: "\u2715"
                        color: "#666666"
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: "#e0e0e0"
            }

            ListView {
                id: addSongListView
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(340, playlistModel.count * 40 + 8)
                clip: true
                model: playlistModel
                spacing: 0

                delegate: Rectangle {
                    width: addSongListView.width
                    height: 40
                    color: addSongHover.hovered ? "#f0f0f0" : "transparent"

                    property bool alreadyAdded: {
                        var _v = window.playlistSongVersion
                        return playlistManager.containsSong(playlistManager.currentPlaylistIndex, filePath)
                    }

                    TapHandler {
                        onTapped: {
                            if (!alreadyAdded) {
                                if (playlistManager.addSongToCurrentPlaylist(filePath)) {
                                    window.showToast(qsTr("已添加到歌单"))
                                } else {
                                    window.showToast(qsTr("该歌曲已在歌单中"))
                                }
                            } else {
                                window.showToast(qsTr("该歌曲已在歌单中"))
                            }
                        }
                    }

                    HoverHandler {
                        id: addSongHover
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        Label {
                            text: title || ""
                            color: alreadyAdded ? "#cccccc" : "#000000"
                            font.pixelSize: 14
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Label {
                            text: alreadyAdded ? qsTr("已添加") : qsTr("添加")
                            color: alreadyAdded ? "#cccccc" : "#1db954"
                            font.pixelSize: 12
                        }
                    }
                }

                Label {
                    anchors.centerIn: parent
                    visible: playlistModel.count === 0
                    text: qsTr("播放列表为空，请先添加歌曲")
                    color: "#999999"
                    font.pixelSize: 13
                }
            }
        }
    }

    // Favorite to playlist popup
    Popup {
        id: favoritePopup
        anchors.centerIn: parent
        width: 300
        height: Math.min(360, favoriteColumn.implicitHeight + 24)
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onOpened: window.isAnyPopupOpen = true
        onClosed: window.isAnyPopupOpen = false
        padding: 12

        background: Rectangle {
            color: "#ffffff"
            radius: 8
            border.color: "#e0e0e0"
            border.width: 1
        }

        contentItem: ColumnLayout {
            id: favoriteColumn
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Label {
                    text: qsTr("收藏到歌单")
                    color: "#000000"
                    font.pixelSize: 15
                    font.bold: true
                    Layout.fillWidth: true
                }
                Button {
                    flat: true
                    implicitWidth: 24
                    implicitHeight: 24
                    onClicked: favoritePopup.close()
                    contentItem: Label {
                        text: "\u2715"
                        color: "#666666"
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: "#e0e0e0"
            }

            Label {
                Layout.fillWidth: true
                Layout.topMargin: 4
                text: player.title || ""
                color: "#888888"
                font.pixelSize: 12
                elide: Text.ElideRight
            }

            ListView {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(300, playlistManager.count * 44 + 8)
                clip: true
                model: playlistManager
                spacing: 0

                delegate: Rectangle {
                    width: ListView.view.width
                    height: 44
                    color: favHover.hovered ? "#f0f0f0" : "transparent"

                    property bool alreadyIn: {
                        var _v = window.playlistSongVersion
                        var curFile = playlistModel.filePath(window.currentIndex)
                        return curFile !== "" && playlistManager.containsSong(index, curFile)
                    }

                    TapHandler {
                        onTapped: {
                            if (!alreadyIn) {
                                var curFile = playlistModel.filePath(window.currentIndex)
                                if (curFile !== "") {
                                    if (playlistManager.addSongToPlaylist(index, curFile)) {
                                        window.showToast(qsTr("已收藏到歌单"))
                                    } else {
                                        window.showToast(qsTr("该歌曲已在歌单中"))
                                    }
                                }
                            } else {
                                window.showToast(qsTr("该歌曲已在歌单中"))
                            }
                        }
                    }

                    HoverHandler { id: favHover }

                    RowLayout {
                        anchors.fill: parent
                        spacing: 10

                        Rectangle {
                            width: 32
                            height: 32
                            radius: 4
                            color: "#1db954"
                            Label {
                                anchors.centerIn: parent
                                text: "\u266B"
                                color: "#ffffff"
                                font.pixelSize: 16
                            }
                        }

                        Label {
                            text: name
                            color: "#000000"
                            font.pixelSize: 14
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Label {
                            text: alreadyIn ? qsTr("已收藏") : ""
                            color: "#cccccc"
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }
    }

    // Import file dialog
    FileDialog {
        id: importFileDialog
        title: qsTr("导入歌曲到歌单")
        fileMode: FileDialog.OpenFiles
        nameFilters: ["Audio Files (*.mp3 *.flac *.wav *.ogg *.aac *.ape)", "All Files (*)"]
        onAccepted: {
            var paths = selectedFiles
            var count = 0
            for (var i = 0; i < paths.length; i++) {
                var path = paths[i].toString()
                if (playlistManager.addSongToCurrentPlaylist(path)) {
                    count++
                }
            }
            if (count === 0 && paths.length > 0) {
                window.showToast(qsTr("所选歌曲已全部在歌单中"))
            } else if (count === paths.length) {
                window.showToast(qsTr("已添加 %1 首歌曲").arg(count))
            } else if (paths.length > count) {
                window.showToast(qsTr("已添加 %1 首，%2 首重复跳过").arg(count).arg(paths.length - count))
            }
        }
    }

    // Playlist sidebar (slides out from right)
    Rectangle {
        id: playlistSidebar
        property bool isOpen: false
        width: 260
        height: Math.min(parent.height - controlBar.height - 56, 420)
        y: parent.height - controlBar.height - height - 12
        color: "#ffffff"
        z: 100
        clip: true
        x: isOpen ? parent.width - width : parent.width

        Behavior on x {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        // 半透明遮罩
        Rectangle {
            x: -playlistSidebar.x
            width: parent.width
            height: parent.height
            color: "#40000000"
            visible: playlistSidebar.isOpen
            TapHandler { onTapped: playlistSidebar.isOpen = false }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.topMargin: 1
            spacing: 0

            // Header
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                color: "#fafafa"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 8
                    spacing: 6

                    Label {
                        text: qsTr("播放列表")
                        color: "#000000"
                        font.pixelSize: 13
                        font.bold: true
                    }
                    Rectangle {
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 16
                        radius: 8
                        color: "#f0f0f0"
                        Label {
                            anchors.centerIn: parent
                            text: playlistModel.count
                            color: "#666666"
                            font.pixelSize: 10
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Button {
                        flat: true
                        implicitWidth: 28
                        implicitHeight: 28
                        onClicked: playlistSidebar.isOpen = false
                        contentItem: Label {
                            text: "\u2715"
                            color: "#999999"
                            font.pixelSize: 14
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: parent.hovered ? "#e8e8e8" : "transparent"
                            radius: 4
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: "#e8e8e8"
            }

            // Song list
            ListView {
                id: playlistSidebarListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: playlistModel
                currentIndex: window.currentIndex
                spacing: 0

                delegate: Rectangle {
                    width: playlistSidebarListView.width
                    height: 36
                    color: ListView.isCurrentItem ? "#f0f7f0" : (sidebarHover.hovered ? "#f5f5f5" : "transparent")

                    TapHandler {
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
                            color: ListView.isCurrentItem ? "#1db954" : "#999999"
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
                            color: ListView.isCurrentItem ? "#1db954" : "#333333"
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
                            color: "#999999"
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
                                color: "#cc0000"
                                font.pixelSize: 11
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                color: parent.hovered ? "#ffe0e0" : "transparent"
                                radius: 4
                            }
                        }
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 1
                        color: "#f0f0f0"
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
                    color: "#999999"
                    font.pixelSize: 13
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: "#e8e8e8"
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
                    color: "#999999"
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: parent.hovered ? "#f5f5f5" : "transparent"
                }
                onClicked: {
                    playlistModel.clear()
                    window.currentIndex = -1
                    player.stop()
                }
            }
        }
    }

    // ===== Playback Functions =====

    function playNext() {
        if (playlistModel.count === 0) return
        var next
        switch (playlistModel.playMode) {
        case 0:
            next = window.currentIndex + 1
            if (next >= playlistModel.count) next = 0
            break
        case 1:
            next = window.currentIndex
            break
        case 2:
            next = Math.floor(Math.random() * playlistModel.count)
            if (playlistModel.count > 1) {
                while (next === window.currentIndex) {
                    next = Math.floor(Math.random() * playlistModel.count)
                }
            }
            break
        default:
            next = window.currentIndex
            break
        }
        window.currentIndex = next
        player.playFile(playlistModel.filePath(next))
    }

    function playPrevious() {
        if (playlistModel.count === 0) return
        var prev
        switch (playlistModel.playMode) {
        case 0:
            prev = window.currentIndex - 1
            if (prev < 0) prev = playlistModel.count - 1
            break
        case 1:
            prev = window.currentIndex
            break
        case 2:
            prev = Math.floor(Math.random() * playlistModel.count)
            if (playlistModel.count > 1) {
                while (prev === window.currentIndex) {
                    prev = Math.floor(Math.random() * playlistModel.count)
                }
            }
            break
        default:
            prev = window.currentIndex
            break
        }
        window.currentIndex = prev
        player.playFile(playlistModel.filePath(prev))
    }

    function autoPlayNext() {
        if (playlistModel.count === 0) return
        var next
        switch (playlistModel.playMode) {
        case 0:
            next = window.currentIndex + 1
            if (next >= playlistModel.count) next = 0
            break
        case 1:
            next = window.currentIndex
            break
        case 2:
            next = Math.floor(Math.random() * playlistModel.count)
            if (playlistModel.count > 1) {
                while (next === window.currentIndex) {
                    next = Math.floor(Math.random() * playlistModel.count)
                }
            }
            break
        default:
            next = window.currentIndex
            break
        }
        window.currentIndex = next
        player.playFile(playlistModel.filePath(next))
    }

    // 提示
    property string toastMessage: ""
    property bool toastVisible: false

    Timer {
        id: toastTimer
        interval: 2000
        onTriggered: toastVisible = false
    }

    Popup {
        id: toastPopup
        anchors.centerIn: parent
        width: toastLabel.implicitWidth + 32
        height: 36
        visible: toastVisible
        closePolicy: Popup.NoAutoClose

        background: Rectangle {
            color: "#cc333333"
            radius: 18
        }

        contentItem: Label {
            id: toastLabel
            text: toastMessage
            color: "#ffffff"
            font.pixelSize: 13
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    function showToast(msg) {
        toastMessage = msg
        toastVisible = true
        toastTimer.restart()
    }
}
