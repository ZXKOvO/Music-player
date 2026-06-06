import QtQuick 2.15

Item {
    Row{
        id:miniRow
        spacing: 15
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 0.02*window.width
        //...
       Image {
            id: miniImg
            anchors.verticalCenter: parent.verticalCenter
            source: "qrc:/img/Resources/title/mini.png"

/*                    Component.onCompleted: {
                console.log(source)
            }*/
        }
       //最小化
        Rectangle{
            id:miniRent
            width: 20
            height: 2
            anchors.verticalCenter: parent.verticalCenter
            color: "#75777f"
            MouseArea{
                anchors.fill: parent
                hoverEnabled: true
                onEntered: {
                    miniRent.color = "white"
                }
                onExited: {
                    miniRent.color = "#75777f"
                }
                onClicked: {
                    window.showMinimized()
                }
            }
        }
        //最大化
        Rectangle{
            id:maxRent
            width: 20
            height: width
            radius: 2
            border.width: 1
            border.color: "#75777f"
            color: "transparent"
            anchors.verticalCenter: parent.verticalCenter
            MouseArea{
                anchors.fill: parent
                hoverEnabled: true
                onEntered: {
                    maxRent.border.color = "white"
                }
                onExited: {
                    maxRent.border.color = "#75777f"
                }
                onClicked: {
                    window.showMaximized()
                }
            }
        }
        //关闭
        Image {
            id: closeImg
            anchors.verticalCenter: parent.verticalCenter
            source: "qrc:/img/Resources/title/close.png"

/*                    Component.onCompleted: {
                console.log(source)
            }*/
            MouseArea{
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    Qt.quit()
                }
            }
        }
    }

}
