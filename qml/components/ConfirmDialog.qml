import QtQuick
import QtQuick.Controls

// 白底黑字确认对话框：白色背景、黑色标题，始终在主窗口中央弹出，供确认提示弹窗复用
Dialog {
    id: root
    anchors.centerIn: Overlay.overlay
    modal: true
    standardButtons: Dialog.Ok | Dialog.Cancel
    width: 320

    background: Rectangle {
        color: "white"
    }

    header: Rectangle {
        color: "white"
        implicitHeight: 44
        Label {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: root.title
            color: "black"
            font.pixelSize: 16
            font.bold: true
        }
    }
}
