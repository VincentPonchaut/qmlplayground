import QtQuick 2.6
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.2
import QtQuick.Layouts 1.3

import Qt.labs.settings 1.0
import Qt.labs.platform 1.0 as Labs
import Qt.labs.lottieqt 1.0

Popup {
    id: fileCreationPopup
    
    width: Math.max(parent.width * 0.33, 400)
    height: Math.max(parent.height * 0.33, 300)
    x: root.width / 2 - width / 2
    y: root.height / 2 - height / 2
    
    clip: true
    padding: 0
    
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
    
    property string folder
    
    function openForFolder(pFolderPath) {
        folder = pFolderPath
        open()
    }
    
    function validate() {
        var folder = fileCreationPopup.folder.replace("file:///", "") + "/"
        var file = newFileNameTextField.text + ".qml"
        
        var success = appControl.createFile(folder, file)
        if (success) {
            // Refresh active folders
            appControl.currentFile = "file:///" + folder + file
            refreshActiveFolders()
        }
        fileCreationPopup.close()
    }
    
    Page {
        anchors.fill: parent
        padding: 0
        
        Component.onCompleted: newFileNameTextField.forceActiveFocus()
        
        header: Pane {
            Material.theme: Material.Dark
            
            Label {
                anchors.centerIn: parent
                font.pointSize: 16
                text: "Create a new file"
            }
        }
        
        Row {
            anchors.centerIn: parent
            spacing: 20
            
            Label {
                id: baseFolderForFileCreationLabel
                text: fileCreationPopup.folder.substring(
                          fileCreationPopup.folder.lastIndexOf(
                              "/") + 1) + "/"
                font.pointSize: 11
                
                MouseArea {
                    id: baseFolderForFileCreationLabelMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                }
                property bool hovered: baseFolderForFileCreationLabelMouseArea.containsMouse
                
                ToolTip.visible: hovered
                ToolTip.text: fileCreationPopup.folder.replace("file:///",
                                                               "")
            }
            TextField {
                id: newFileNameTextField
                anchors.baseline: baseFolderForFileCreationLabel.baseline
                placeholderText: "Enter file name"
                text: "main"
                font.pointSize: baseFolderForFileCreationLabel.font.pointSize
                selectByMouse: true
                
                onAccepted: fileCreationPopup.validate()
            }
            Label {
                anchors.baseline: baseFolderForFileCreationLabel.baseline
                text: ".qml"
                font.pointSize: 11
            }
        }
        
        footer: Pane {
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                spacing: 10
                
                Button {
                    text: "Create"
                    onClicked: fileCreationPopup.validate()
                }
                Button {
                    text: "Cancel"
                    onClicked: fileCreationPopup.close()
                }
            }
        }
    }
}
