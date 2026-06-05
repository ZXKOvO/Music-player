import QtQuick

Window {
    width: 1317
    height: 933
    visible: true
    title: qsTr("Hello World")
    flags:  Qt.FramelessWindowHint | Qt.Window | Qt.WindowSystemMenuHint |
            Qt.WindowMaximizeButtonHint | Qt.WindowMinimizeButtonHint           //设置无边框属性

    Rectangle{
        id:leftRect
        width: 255
        anchors.top: parent.top
        anchors.bottom: bottomRect.top
        color: "#1a1a21"
    }

    Rectangle{
        id:rightRect
        anchors.left: leftRect.right
        anchors.right:  parent.right
        anchors.top: parent.top
        anchors.bottom: bottomRect.top
        color: "#13131a"
    }

    Rectangle{
        id:bottomRect
        height: 255
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right:  parent.right
        color: "#2d2d37"
    }
}
