import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Window
import MusicPlayer

// 主窗口：应用入口，管理全局状态和页面切换
ApplicationWindow {
    id: window
    width: 1000
    height: 500
    visible: true
    title: qsTr("Music Player")
    color: "black"

    property int currentIndex: -1           // 当前播放歌曲在播放列表中的索引
    property string leftView: "search"      // 左侧面板当前显示的页面
    property int detailSongCount: 0         // 当前歌单详情页的歌曲数量
    property int playlistSongVersion: 0     // 歌单歌曲变化版本号，用于触发 UI 刷新
    property bool isAnyPopupOpen: false     // 是否有弹窗打开，用于屏蔽歌词点击跳转
    property bool leftPanelVisible: true    // 左侧面板是否可见

    // 播放列表数据模型：管理当前播放队列和播放模式
    PlaylistModel { id: playlistModel }

    // 歌单管理器：管理用户创建的多个命名歌单，支持持久化
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

    // 播放控制器：管理音频播放、进度、音量等
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

    // 懒加载创建桌面歌词窗口（首次使用时创建，后续复用）
    function ensureDesktopLyricsWindow() {
        if (!desktopLyricsObj) {
            desktopLyricsObj = desktopLyricsComponent.createObject(null)
        }
        return desktopLyricsObj
    }

    // 桌面歌词窗口组件（动态创建）
    Component {
        id: desktopLyricsComponent
        // 桌面歌词浮动窗口：透明背景，置顶显示，支持拖动
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
            property color lyricsColor: "limegreen"
            property var colorList: ["green", "cyan", "yellow", "orange", "deeppink", "purple", "white"]

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0.1, 0.1, 0.1, 0.8)
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
                                               ? desktopLyricsWindow.lyricsColor : "lightgray"
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
                                        color: "gray"
                                        font.pixelSize: 14
                                    }
                                }
                            }
                        }

                        Label {
                            anchors.centerIn: parent
                            visible: player.lyrics.lineCount === 0
                            color: "gray"
                            font.pixelSize: 16
                            text: player.title ? "暂无歌词" : "请播放歌曲"
                        }

                        // 颜色选择按钮
                        Button {
                            anchors.right: closeBtn.left
                            anchors.top: parent.top
                            anchors.margins: 4
                            width: 20
                            height: 20
                            flat: true
                            z: 2
                            onClicked: colorPickerPopup.open()
                            contentItem: Rectangle {
                                width: 12; height: 12; radius: 6
                                color: desktopLyricsWindow.lyricsColor
                                border.color: "gray"; border.width: 1
                            }
                            background: Rectangle {
                                color: parent.hovered ? "dimgray" : "transparent"
                                radius: 10
                            }
                        }

                        // 关闭按钮（右上角）
                        Button {
                            id: closeBtn
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
                                color: "gray"
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                color: parent.hovered ? "dimgray" : "transparent"
                                radius: 10
                            }
                        }

                        // 颜色选择弹窗
                        Popup {
                            id: colorPickerPopup
                            x: closeBtn.x - width
                            y: closeBtn.y
                            width: colorRow.width + 16
                            height: 36
                            padding: 8
                            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

                            background: Rectangle {
                                color: Qt.rgba(0.13, 0.13, 0.13, 0.93)
                                radius: 8
                                border.color: "dimgray"
                                border.width: 1
                            }

                            Row {
                                id: colorRow
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6

                                Repeater {
                                    model: desktopLyricsWindow.colorList
                                    Rectangle {
                                        width: 18; height: 18; radius: 9
                                        color: modelData
                                        border.color: desktopLyricsWindow.lyricsColor === modelData ? "white" : "dimgray"
                                        border.width: desktopLyricsWindow.lyricsColor === modelData ? 2 : 1
                                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                                        TapHandler {
                                            onTapped: {
                                                desktopLyricsWindow.lyricsColor = modelData
                                                colorPickerPopup.close()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // 分割线
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.leftMargin: 10
                        Layout.rightMargin: 10
                        Layout.preferredHeight: 1
                        color: "gray"
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
                                color: "gray"
                                font.pixelSize: 14
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                color: parent.hovered ? "dimgray" : "transparent"
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
                                color: "limegreen"
                                font.pixelSize: 18
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                color: parent.hovered ? "dimgray" : "transparent"
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
                                color: "gray"
                                font.pixelSize: 14
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                color: parent.hovered ? "dimgray" : "transparent"
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

    // 主布局：左侧面板 + 右侧歌词 + 底部控制栏
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // 顶部区域：左侧面板 + 歌词页面并排显示
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // 左侧面板：搜索 + 我的歌单（可折叠）
            Rectangle {
                id: leftPanel
                Layout.fillHeight: true
                Layout.preferredWidth: 350
                visible: window.leftPanelVisible
                color: "white"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // 导航标签栏：搜索/我的歌单切换
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        color: "whitesmoke"

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
                                    color: window.leftView === "search" ? "limegreen" : "dimgray"
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
                                        color: "limegreen"
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
                                    color: window.leftView === "playlists" ? "limegreen" : "dimgray"
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
                                        color: "limegreen"
                                        visible: window.leftView === "playlists"
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: "lightgray"
                    }

                    // 内容区域：栈视图管理页面切换
                    StackView {
                        id: leftStackView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        initialItem: searchViewComp
                    }
                }
            }

            // 分隔线 + 折叠按钮
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: window.leftPanelVisible ? 18 : 22
                color: "lightgray"

                // 点击分隔线任意位置切换折叠
                TapHandler {
                    onTapped: window.leftPanelVisible = !window.leftPanelVisible
                }

                // 折叠按钮（面板展开时显示）
                Button {
                    id: collapseBtn
                    anchors.centerIn: parent
                    width: 16
                    height: 60
                    flat: true
                    z: 10
                    visible: window.leftPanelVisible
                    onClicked: window.leftPanelVisible = false
                    contentItem: Label {
                        text: "\u25C0"
                        color: collapseBtn.hovered ? "limegreen" : "dimgray"
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: collapseBtn.hovered ? Qt.rgba(0, 0, 0, 0.08) : "transparent"
                        radius: 4
                    }
                }

                // 展开按钮（面板收起时显示）
                Button {
                    id: expandBtn
                    anchors.centerIn: parent
                    width: 20
                    height: 80
                    flat: true
                    z: 10
                    visible: !window.leftPanelVisible
                    onClicked: window.leftPanelVisible = true
                    contentItem: Label {
                        text: "\u25B6"
                        color: expandBtn.hovered ? "limegreen" : "dimgray"
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: expandBtn.hovered ? Qt.rgba(0, 0, 0, 0.08) : "transparent"
                        radius: 4
                    }
                }
            }

            // 右侧区域：歌词页面
            LyricsPage {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }

        // 底部控制栏：播放控制、进度条、音量等
        ControlBar {
            id: controlBar
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(48, window.height * 0.11)
        }
    }

    // ===== 页面组件 =====

    // 歌单列表页组件
    Component {
        id: playlistsViewComp
        PlaylistsPage {}
    }

    // 搜索页组件
    Component {
        id: searchViewComp
        SearchPage {}
    }

    // 歌单详情页组件
    Component {
        id: playlistDetailComp
        PlaylistDetailPage {}
    }

    // ===== 对话框和弹窗 =====

    // 文件选择对话框：选择本地音频文件（内置对话框支持多选）
    function openFileDialog() {
        var helper = Qt.createQmlObject("import MusicPlayer; FileDialogHelper {}", window);
        var filter = qsTr("Audio Files (*.mp3 *.flac *.wav *.ogg *.aac *.ape);;All Files (*)");
        var paths = helper.openFiles(qsTr("Select Audio File"), filter);
        helper.destroy();
        if (paths.length === 0) return;
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

    // 新建歌单对话框
    ConfirmDialog {
        id: createPlaylistDialog
        title: qsTr("新建歌单")
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
                color: "black"
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

    // 添加到歌单弹窗：选择歌曲添加到指定歌单
    Popup {
        id: addToPlaylistPopup
        anchors.centerIn: parent
        width: 360
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onOpened: window.isAnyPopupOpen = true
        onClosed: window.isAnyPopupOpen = false

        background: Rectangle {
            color: "white"
            radius: 8
            border.color: "lightgray"
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
                    color: "black"
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
                        color: "dimgray"
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: "lightgray"
            }

            ListView {
                id: addSongListView
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(60, Math.min(340, playlistModel.count * 40 + 8))
                clip: true
                model: playlistModel
                spacing: 0

                delegate: Rectangle {
                    width: addSongListView.width
                    height: 40
                    color: addSongHover.hovered ? "whitesmoke" : "transparent"

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
                            color: alreadyAdded ? "lightgray" : "black"
                            font.pixelSize: 14
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Label {
                            text: alreadyAdded ? qsTr("已添加") : qsTr("添加")
                            color: alreadyAdded ? "lightgray" : "limegreen"
                            font.pixelSize: 12
                        }
                    }
                }

                Label {
                    anchors.centerIn: parent
                    visible: playlistModel.count === 0
                    text: qsTr("播放列表为空，请先添加歌曲")
                    color: "gray"
                    font.pixelSize: 13
                }
            }
        }
    }

    // 收藏到歌单弹窗：将当前歌曲收藏到歌单
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
            color: "white"
            radius: 8
            border.color: "lightgray"
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
                    color: "black"
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
                        color: "dimgray"
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: "lightgray"
            }

            Label {
                Layout.fillWidth: true
                Layout.topMargin: 4
                text: player.title || ""
                color: "gray"
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
                    color: favHover.hovered ? "whitesmoke" : "transparent"

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
                            color: "limegreen"
                            Label {
                                anchors.centerIn: parent
                                text: "\u266B"
                                color: "white"
                                font.pixelSize: 16
                            }
                        }

                        Label {
                            text: name
                            color: "black"
                            font.pixelSize: 14
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Label {
                            text: alreadyIn ? qsTr("已收藏") : ""
                            color: "lightgray"
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }
    }

    // 导入歌曲对话框：批量导入歌曲到歌单（内置对话框支持多选）
    function openImportFileDialog() {
        var helper = Qt.createQmlObject("import MusicPlayer; FileDialogHelper {}", window);
        var filter = qsTr("Audio Files (*.mp3 *.flac *.wav *.ogg *.aac *.ape);;All Files (*)");
        var paths = helper.openFiles(qsTr("导入歌曲到歌单"), filter);
        helper.destroy();
        if (paths.length === 0) return;
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

    // 播放列表悬停触发区域：鼠标移到右侧边缘时自动打开播放列表
    Item {
        anchors.right: parent.right
        width: 10
        height: parent.height - controlBar.height
        z: 50

        HoverHandler {
            onHoveredChanged: {
                if (hovered) {
                    playlistSidebar.isOpen = true
                    playlistSidebar.closeTimer.stop()
                }
            }
        }
    }

    // 播放列表侧边栏：从右侧滑出，显示当前播放队列
    PlaylistSidebar {
        id: playlistSidebar
        controlBarHeight: controlBar.height
    }

    // ===== 播放功能 =====

    // 下一首：根据播放模式（循环/单曲/随机）切换到下一首
    function playNext() {
        if (playlistModel.count === 0) return
        var next
        switch (playlistModel.playMode) {
        case 0: // 列表循环
        case 1: // 单曲循环（手动切歌时按顺序）
            next = window.currentIndex + 1
            if (next >= playlistModel.count) next = 0
            break
        case 2: // 随机播放
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

    // 上一首：根据播放模式切换到上一首
    function playPrevious() {
        if (playlistModel.count === 0) return
        var prev
        switch (playlistModel.playMode) {
        case 0: // 列表循环
        case 1: // 单曲循环（手动切歌时按顺序）
            prev = window.currentIndex - 1
            if (prev < 0) prev = playlistModel.count - 1
            break
        case 2: // 随机播放
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

    // 自动播放下一首：播放结束信号触发，与 playNext 区别在于单曲循环时重复当前歌曲
    function autoPlayNext() {
        if (playlistModel.count === 0) return
        var next
        switch (playlistModel.playMode) {
        case 0: // 列表循环
            next = window.currentIndex + 1
            if (next >= playlistModel.count) next = 0
            break
        case 1: // 单曲循环
            next = window.currentIndex
            break
        case 2: // 随机播放
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
            color: Qt.rgba(0.2, 0.2, 0.2, 0.85)
            radius: 18
        }

        contentItem: Label {
            id: toastLabel
            text: toastMessage
            color: "white"
            font.pixelSize: 13
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    // 显示 Toast 提示消息，2 秒后自动消失
    function showToast(msg) {
        toastMessage = msg
        toastVisible = true
        toastTimer.restart()
    }
}
