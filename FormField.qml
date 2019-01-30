import QtQuick 2.12
import QtQuick.Controls 2.4

Row {
    width: parent.width
    anchors.left: parent.left
    anchors.right: parent.right
    spacing: 30
    height: 50

    property alias label: formLabel.text
    property int remainingWidth: width - formLabel.width - spacing
    
    Label {
        id: formLabel

        width: parent.width * 1/4
        anchors.verticalCenter: parent.verticalCenter
        horizontalAlignment: Text.AlignRight
        
        text: "Project Name:"
    }
}
