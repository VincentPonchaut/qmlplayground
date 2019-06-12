import QtQuick 2.6
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.0
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import Qt.labs.platform 1.0 as Labs

//Page {
Pane {
    id: optionsPane

    // Settings
    property alias xRatio: xRatioSlider.value
    property alias yRatio: yRatioSlider.value
    property alias showBackground: showContentBackgroundCheckBox.checked
    property alias clearConsoleOnReload: clearConsoleCheckbox.checked

    Material.theme: Material.Dark
    background: Rectangle { color: "#1d1d1d" }

    Row {
        id: contentPageHeader
        spacing: 20
        
//        width: parent.width * 0.85
        anchors.horizontalCenter: parent.horizontalCenter
        
        CheckBox {
            id: showContentBackgroundCheckBox
            text: "Background"
        }
        
        Column {
            id: sizeRatioColumn
            height: parent.height
            
            Row {
                height: parent.height * 0.5
                Label {
                    text: "Width "
                    anchors.verticalCenter: parent.verticalCenter
                }
                Slider {
                    id: xRatioSlider
                    anchors.verticalCenter: parent.verticalCenter
                    from: 0
                    to: 100
                    stepSize: 5
                }
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "%1\%".arg(Math.floor(xRatioSlider.value))
                }
            }
            Row {
                height: parent.height * 0.5
                Label {
                    text: "Height"
                    anchors.verticalCenter: parent.verticalCenter
                }
                Slider {
                    id: yRatioSlider
                    anchors.verticalCenter: parent.verticalCenter
                    from: 0
                    to: 100
                    stepSize: 5
                }
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "%1\%".arg(Math.floor(yRatioSlider.value))
                }
            }
        }

        // Clear console checkbox
        CheckBox {
            id: clearConsoleCheckbox
            anchors.verticalCenter: parent.verticalCenter

            text: "Clear console on reload"
        }

        // Publish button
        Button {
            anchors.verticalCenter: parent.verticalCenter

            text: "Publish"
            onClicked: publishDialog.open()
        }

    } // end contentPageHeader

    
    states: [
        State {
            name: "open"
            PropertyChanges {
                target: optionsPane
                y: 0
            }
        },
        State {
            name: "closed"
            
            PropertyChanges {
                target: optionsPane
                y: -optionsPane.height
            }
            AnchorChanges {
                target: optionsPane
                anchors.top: undefined //remove myItem's left anchor
            }
        }
    ]
    state: "closed"
    
    transitions: Transition {
        from: "open"
        to: "closed"
        reversible: true
        
        NumberAnimation { properties: "y"; easing.type: Easing.InOutQuad }
    }
    
    function toggle() {
        state = (state == "open" ? "closed" : "open");
    }
}
