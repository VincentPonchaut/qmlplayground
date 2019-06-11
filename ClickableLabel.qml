import QtQuick 2.6
import QtQuick.Controls 2.2
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.2
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import Qt.labs.platform 1.0 as Labs

//Page {
Label {
    id: clickableLabel
    font.underline: hovered
    
    property alias hovered: innerMouseArea.containsMouse
    signal clicked();
    
    MouseArea {
        id: innerMouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: clickableLabel.clicked();
    }
}
