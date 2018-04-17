import QtQuick 2.6
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import Qt.labs.platform 1.0 as Labs

RoundButton
{
    property alias imageSource: img.source
    
    Image {
        id: img
        anchors.fill: parent
        anchors.margins: 5
        
        fillMode: Image.PreserveAspectFit
        smooth: true
    }
    
    ToolTip.visible: hovered
}
