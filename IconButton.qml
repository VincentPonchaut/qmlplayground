import QtQuick 2.6
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.2

RoundButton
{
    id: roundButton

    property alias imageSource: img.source
    property int margins: 5
    property var __img__: img
    
    Image {
        id: img
        anchors.fill: parent
        anchors.margins: roundButton.margins
        
        fillMode: Image.PreserveAspectFit
        smooth: true
        sourceSize.width: width
        sourceSize.height: height
    }
    
    ToolTip.visible: hovered
}
