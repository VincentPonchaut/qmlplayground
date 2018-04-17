import QtQuick 2.6
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import Qt.labs.platform 1.0 as Labs

//Page {
ToolBar {

    RowLayout {
        anchors.fill: parent
        
        ToolButton {
            onClicked: folderSelectorPane.toggle()
            
            Image {
                id: menuIcon
                anchors.fill: parent
                anchors.margins: 5
                
                fillMode: Image.PreserveAspectFit
                
                states: [
                    State {
                        name: "open"
                        when: folderSelectorPane.state == "open"
                        PropertyChanges {
                            target: menuIcon
                            source: "qrc:///img/backArrow.svg"
                        }
                    },
                    State {
                        name: "closed"
                        when: folderSelectorPane.state == "closed"
                        PropertyChanges {
                            target: menuIcon
                            source: "qrc:///img/menu.svg"
                        }
                    }
                ]
            }
            
            ToolTip.visible: hovered
            ToolTip.text: folderSelectorPane.state == "open" ? "Hide folders":
                                                               "Show folders"
        }
        Row {
            Layout.fillWidth: true
            height: parent.height
            spacing: 5
            
            Label {
                id: folderLabel
                anchors.verticalCenter: parent.verticalCenter
                text: "" + appControl.currentFile
                elide: Label.ElideRight
                verticalAlignment: Qt.AlignVCenter
            }
            

        }

        ToolButton {
            id: editToolButton
            text: "Edit"
            enabled: appControl.currentFile.length > 0
            onClicked: Qt.openUrlExternally(appControl.currentFile)
        }

        IconButton {
            Material.theme: Material.Dark
            imageSource: "qrc:///img/code.svg"
            onClicked: quickEditor.toggle()
            ToolTip.text: "Toggle quick editor"
        }
        
        RoundButton {
            Material.theme: Material.Dark
            enabled: root.currentFolder.length > 0
            anchors.rightMargin: 20
            text: "x"
            onClicked: root.currentFolder = ""
            
            ToolTip.visible: hovered
            ToolTip.text: "Close current folder"
        }
    }
}
