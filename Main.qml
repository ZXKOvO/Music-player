import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import MusicPlayer

ApplicationWindow {
    id: window
    width: 1000
    height: 500
    visible: true
    title: qsTr("Music Player")
    color: "#2b2b2b"

    property int currentIndex: -1
    property string leftView: "main"
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
        Component.onCompleted: registerCoverProvider() // 注册封面 ImageProvider 到 QML 引擎
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

        // Top area: playlist + lyrics side by side
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // Left: Playlist panel with view switching
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
                                text: qsTr("播放列表")
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                flat: true
                                onClicked: {
                                    window.leftView = "main"
                                    leftStackView.pop(null)
                                }
                                contentItem: Label {
                                    text: qsTr("播放列表")
                                    color: window.leftView === "main" ? "#1db954" : "#666666"
                                    font.pixelSize: 14
                                    font.bold: window.leftView === "main"
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
                                        visible: window.leftView === "main"
                                    }
                                }
                            }

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
                        initialItem: mainPlaylistViewComp
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
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(48, window.height * 0.11)
        }
    }

    // ===== Page Components =====

    Component {
        id: mainPlaylistViewComp
        PlaylistPage {}
    }

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
        height: Math.min(400, addToPlaylistColumn.height + 24)
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
