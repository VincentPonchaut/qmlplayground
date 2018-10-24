import QtQuick 2.6
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

//Page {
IconButton {
    id: root
    
    width: height
    background: Rectangle {
        radius: width / 2
        color: root.hovered ? "#3d3d3d" :
                              "transparent"
    }
    
    checkable: true

    ColorOverlay {
        anchors.fill: root.__img__
        source: root.__img__
        color: Material.accent
        visible: root.checked
    }
}

