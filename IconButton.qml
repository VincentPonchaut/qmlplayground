import QtQuick 2.6
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.2
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import Qt.labs.platform 1.0 as Labs

RoundButton
{
    id: roundButton

    property alias imageSource: img.source
    property int margins: 5
    
    Image {
        id: img
        anchors.fill: parent
        anchors.margins: roundButton.margins
        
        fillMode: Image.PreserveAspectFit
        smooth: true
    }
    
    ToolTip.visible: hovered
}
