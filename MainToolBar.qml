import QtQuick 2.6
import QtQuick.Controls 2.2
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.2
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

        IconButton {
            id: consoleToolButton
            text: ""

            Material.theme: Material.Dark
            flat: true
            imageSource: "qrc:///img/console.svg"
            margins: 10
            onClicked: theConsole.toggle()

            ToolTip.visible: hovered
            ToolTip.text: "%1 console".arg(theConsole.state == "open" ? "Hide":
                                                                        "Show");
        }

        ToolButton {
            id: dataToolButton
            text: "Data"
            enabled: dataManager.currentDataFile.length > 0
            onClicked: dataManager.requestEditData()

            ToolTip.visible: hovered
            ToolTip.text: "Edit data"
        }

        IconButton {
            id: serverToolButton
            Material.theme: Material.Dark
            flat: true
            imageSource: "qrc:///img/smartphone.svg"
            visible: serverControl.available

            onClicked: {
                appControl.setClipboardText(serverControl.hostAddress);
                // TODO: toast "Address copied to clipboard"
            }
            ToolTip.text: "To broadcast to remote devices, \nconnect to %1 \non the same network as this machine".arg(serverControl.hostAddress);

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: width / 5
                anchors.rightMargin: width / 5
                anchors.right: parent.right

                visible: serverControl.activeClients > 0

                width: parent.width * 0.35
                height: width
                radius: width / 2

                color: Material.accent

                Text {
                    anchors.centerIn: parent
                    text: serverControl.activeClients
                }
            }
        }

        ToolButton {
            id: editToolButton
            text: "Edit"
            enabled: appControl.currentFile.length > 0
            onClicked: Qt.openUrlExternally(appControl.currentFile)

            ToolTip.visible: hovered
            ToolTip.text: "Edit current file externally"
        }

        IconButton {
            Material.theme: Material.Dark
            flat: true
            imageSource: "qrc:///img/code.svg"
            onClicked: quickEditor.toggle()
            ToolTip.text: quickEditor.state != "open" ? "Show quick editor":
                                                        "Hide quick editor"
        }

        RoundButton {
            id: helpButton

            Material.theme: Material.Dark
            flat: true

            Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                anchors.margins: 5
                source: "qrc:///img/help.svg"
                mipmap: true
            }

            ToolTip.visible: hovered
            ToolTip.text: "\n"
                + "Filter files"         + ": %1 \n".arg(shortcutFileFilter.sequence)
                + "Toggle folder panel"  + ": %1 \n".arg(shortcutFolderSelectorPane.sequence)
                + "Toggle quick editor"  + ": %1 \n".arg(quickEditorToggleShortcut.sequence)
                + "Toggle options panel" + ": %1 \n".arg(shortcutOptionsPane.sequence)
            ;
        }

        RoundButton {
            id: optionsPaneToggleButton

            Material.theme: Material.Dark
            flat: true

            Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                anchors.margins: 5
                source: "qrc:///img/gear.png"
                mipmap: true
            }

            onClicked: optionsPane.toggle()

            ToolTip.visible: hovered
            ToolTip.text: optionsPane.state == "open" ? "Hide options (F1)":
                                                        "Show options (F1)"
        }
    }
}
