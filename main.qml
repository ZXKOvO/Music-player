import QtQuick
import QtQuick.Window
import "./Src/leftPage"
import "./Src/rightPage"
import "./Src/playMusic"

Window {
    id:window
    width: 1317
    height: 933
    visible: true
    title: qsTr("Music Player")
    //flags:  Qt.FramelessWindowHint | Qt.Window | Qt.WindowSystemMenuHint |
           // Qt.WindowMaximizeButtonHint | Qt.WindowMinimizeButtonHint           //设置无边框属性

    LeftPage{
        id:leftRect
        width: 255
        anchors.top: parent.top
        anchors.bottom: bottomRect.top
        color: "#1a1a21"
    }

    RightPage{
        id:rightRect
        anchors.left: leftRect.right
        anchors.right:  parent.right
        anchors.top: parent.top
        anchors.bottom: bottomRect.top
        color: "#13131a"
    }

    PlayMusic{
        id:bottomRect
        height: 100
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right:  parent.right
        color: "#2d2d37"
    }
}
