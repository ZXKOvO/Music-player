import QtQuick 2.15
import QtQuick.Controls
import "../title"

Rectangle{
    id:rightRect

    //登陆
    Row{
        id:othersRow
        spacing: 5
        anchors.verticalCenter: minMax.verticalCenter
        anchors.right: minMax.left
        anchors.rightMargin: 10

        //登录与会员
        Item{
            id:userItem
            width: 140
            height: 30
            anchors.verticalCenter: parent.verticalCenter
            Row{
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                Rectangle{
                    id:userIconRect
                    width: 25
                    height: width
                    radius: width/2
                    color: "#2d2d37"
                    Image{
                        scale: 0.7
                        source: "qrc:/img/Resources/title/user.png"
                        anchors.centerIn:parent
                    }
                    MouseArea{
                        anchors.fill: parent
                        onClicked: {
                        }
                    }
                }
                Text{
                    id:loadStateText
                    text: "未登录"
                    color:"#75777f"
                    font.pixelSize: 14
                    font.family:"微软雅黑 Light"
                    anchors.verticalCenter:userIconRect.verticalCenter
                    MouseArea{
                        anchors.fill: parent
                        hoverEnabled: true
                        onExited: {
                            loadStateText.color = "#75777f"
                        }
                        onEntered: {
                            loadStateText.color = "white"
                        }
                        onClicked: {
                        }
                    }
               }
            }
        }

        //会员标识
        Item{
            height: userIconRect.height
            width: loadStateText.implicitWidth * 1.2
            anchors.verticalCenter:parent.verticalCenter
            Rectangle{
                id:vipRect
                width: parent.width
                height: 12
                radius: height/2
                color: "#dadada"
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                Label{
                    text: "VIP开通"
                    anchors.left: parent.left
                    anchors.leftMargin: parent.radius*2 + 5
                    color: "black"
                    font.pixelSize: parent.height/2 + 2
                    font.family: "微软雅黑 Light"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            Rectangle{
                id:bgBordRect
                width: vipRect.height + 4
                height: width
                radius: width/2
                color: "#dadada"
                border.width: 1
                border.color: "#13131a"
                anchors.verticalCenter: parent.verticalCenter
            }
        }


        //登录下拉
        Image{
            id:loginImg
            anchors.verticalCenter: parent.verticalCenter
            source: "qrc:/img/Resources/title/arrow.png"
            rotation: -90
            MouseArea{
                anchors.fill: parent
                hoverEnabled: true
                onExited: {
                    parent.layer.enabled = false
                }
                onEntered: {
                    parent.layer.enabled = true
                }
                onClicked: {
                    BasicConfig.openLoginPopup()
                }
            }
        }

        //消息中心
        Image{
            id:messageImg
            anchors.verticalCenter: parent.verticalCenter
            source: "qrc:/img/Resources/title/message.png"
            layer.enabled: false
            scale: 0.7
            MouseArea{
                anchors.fill: parent
                hoverEnabled: true
                onExited: {
                    parent.layer.enabled = false
                }
                onEntered: {
                    parent.layer.enabled = true
                }
                onClicked: {

                }
            }
        }
        //设置
        Image{
            id:settingImg
            anchors.verticalCenter: parent.verticalCenter
            source: "qrc:/img/Resources/title/setting.png"
            layer.enabled: false
            scale: 0.7
            MouseArea{
                anchors.fill: parent
                hoverEnabled: true
                onExited: {
                    parent.layer.enabled = false
                }
                onEntered: {
                    parent.layer.enabled = true
                }
                onClicked: {
                    titleRoot.typeClicked(1)
                }
            }
        }
        //换肤
        Image{
            id:skinImg
            anchors.verticalCenter: parent.verticalCenter
            source: "qrc:/img/Resources/title/skin.png"
            layer.enabled: false
            scale: 0.7
            MouseArea{
                anchors.fill: parent
                hoverEnabled: true
                onExited: {
                    parent.layer.enabled = false
                }
                onEntered: {
                    parent.layer.enabled = true
                }
                onClicked: {
                    titleRoot.typeClicked(0)
                }
            }
        }
        Rectangle{
            height: 24
            width: 1
            color:"white"
            anchors.verticalCenter: parent.verticalCenter
        }
    }


    //min,max,exit
    MinAndMax{
        id:minMax
        width: 180
//        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 60
    }
}