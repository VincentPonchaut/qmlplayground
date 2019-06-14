import QtQuick 2.6
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

//Page {
MenuItem {
    id: control

    property alias iconFile: menuItemIconImg.source
    property alias description: menuItemDesc.text
    
    height: 60

    contentItem: Item {
        anchors.fill: parent
        anchors.leftMargin: 10
//        padding: 0
        
        Rectangle {
            id: menuItemIcon
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height * 0.5
            width: height

            color: "transparent"

            Image {
                id: menuItemIconImg
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                sourceSize.width: width
                sourceSize.height: height
//                mipmap: true
                smooth: true
            }

            ColorOverlay {
                anchors.fill: menuItemIconImg
                source: menuItemIconImg
                color: Material.foreground
            }
        }
        
        Label {
            id: menuItemLabel
            height: 30
            anchors.left: menuItemIcon.right
            anchors.leftMargin: 10
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.top: parent.top

            text: control.text
            font: control.font
            verticalAlignment: Text.AlignVCenter
        }
        Label {
            id: menuItemDesc
            height: 10
            anchors.top: menuItemLabel.bottom
            anchors.topMargin: 5
            anchors.left: menuItemIcon.right
            anchors.leftMargin: 5
            anchors.right: parent.right
            anchors.rightMargin: 5
            
            wrapMode: Text.Wrap
            
            font.pointSize: 8
            font.family: "Segoe UI"
            font.italic: true
            color: "grey"
            verticalAlignment: Text.AlignVCenter
        }
    }
    
}
