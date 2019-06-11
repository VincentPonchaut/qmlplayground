import QtQuick 2.6
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

RoundButton
{
    id: roundButton

    property alias imageSource: img.source
    property int margins: 5
    property var __img__: img
    property alias color: colorOverlay.color
    property bool enableTooltip: true
        
    Material.theme: Material.Dark
    flat: true

    Image {
        id: img
        anchors.fill: parent
        anchors.margins: roundButton.margins
        
        fillMode: Image.PreserveAspectFit
        smooth: true
        sourceSize.width: width
        sourceSize.height: height
    }
    ColorOverlay {
        id: colorOverlay
        anchors.fill: img
        source: img
        color: Material.foreground
    }
    
    ToolTip.visible: enableTooltip && hovered
}
