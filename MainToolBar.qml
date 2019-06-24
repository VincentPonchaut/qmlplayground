import QtQuick 2.6
import QtQuick.Controls 2.2
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.2
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import Qt.labs.platform 1.0 as Labs

//Page {
ToolBar {
    id: mainToolBar

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
            
            IconButton {
                id: openCurrentFolderButton

                flat: true
                imageSource: "qrc:///img/folder.svg"
                onClicked: Qt.openUrlExternally(appControl.currentFolder)

                ToolTip.visible: hovered
                ToolTip.text: "Open in explorer"
            }

            ClickableLabel {
                id: folderLabel
                anchors.verticalCenter: parent.verticalCenter

                property string currentFileName: "" + appControl.currentFile.replace(appControl.currentFolder.substring(0, appControl.currentFolder.lastIndexOf("/") + 1), "")

                text: currentFileName
                elide: Label.ElideLeft
                verticalAlignment: Qt.AlignVCenter

                ToolTip.visible: hovered
                ToolTip.text: "Open %1 in the default editor".arg(currentFileName)

                onClicked: Qt.openUrlExternally(appControl.currentFile)
            }
            

        }

        IconButton {
            id: consoleToolButton
            text: ""

            flat: true
            imageSource: "qrc:///img/console.svg"
            margins: 10
            onClicked: theConsole.toggle()

            ToolTip.visible: hovered
            ToolTip.text: "%1 console".arg(theConsole.state == "open" ? "Hide":
                                                                        "Show");

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: width / 5
                anchors.rightMargin: width / 5
                anchors.right: parent.right

                visible: theConsole.unreadMessages > 0

                width: parent.width * 0.35
                height: width
                radius: width / 2

                color: Material.accent

                Text {
                    anchors.centerIn: parent
                    text: theConsole.unreadMessages
                }
            }
        }

//        ToolButton {
//            id: dataToolButton
//            text: "Data"
//            enabled: dataManager.dataFiles.length == 0 || Manager.currentDataFile.length > 0
//            onClicked: dataManager.requestEditData()

//            ToolTip.visible: hovered
//            ToolTip.text: "Edit data"
//        }

        IconButton {
            id: serverToolButton
            Material.theme: Material.Dark
            flat: true
            imageSource: "qrc:///img/smartphone.svg"
            visible: serverControl.available

            onClicked: {
                appControl.setClipboardText(serverControl.hostAddress);
                // TODO: toast "Address copied to clipboard"

                serverDialog.open()
            }
            ToolTip.text: "To broadcast to remote devices, \nconnect to one of the following\n%1 \non the same network as this machine".arg(serverControl.hostAddress);

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

//        ToolButton {
//            id: editToolButton
//            text: "Edit"
//            enabled: appControl.currentFile.length > 0
//            onClicked: Qt.openUrlExternally(appControl.currentFile)

//            ToolTip.visible: hovered
//            ToolTip.text: "Edit current file externally"
//        }

        IconButton {
            Material.theme: Material.Dark
            flat: true
            imageSource: "qrc:///img/code.svg"
            onClicked: quickEditor.toggle()
            ToolTip.text: quickEditor.state != "open" ? "Show quick editor":
                                                        "Hide quick editor"
        }

//        RoundButton {
//            id: helpButton

//            Material.theme: Material.Dark
//            flat: true

//            Image {
//                anchors.fill: parent
//                fillMode: Image.PreserveAspectFit
//                anchors.margins: 5
//                source: "qrc:///img/help.svg"
//                mipmap: true
//            }

//            ToolTip.visible: hovered
//            ToolTip.text: "\n"
//                + "Filter files"         + ": %1 \n".arg(shortcutFileFilter.sequence)
//                + "Toggle folder panel"  + ": %1 \n".arg(shortcutFolderSelectorPane.sequence)
//                + "Toggle quick editor"  + ": %1 \n".arg(quickEditorToggleShortcut.sequence)
//                + "Toggle options panel" + ": %1 \n".arg(shortcutOptionsPane.sequence)
//            ;
//        }

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

        // Overflow
        IconButton {
            id: overflowButton

            flat: true
            imageSource: "qrc:///img/overflow.svg"
            margins: 12

            enableTooltip: false
            onClicked: {
                if (!optionsMenu.visible)
                    optionsMenu.open()
                else
                    optionsMenu.close()
            }

            Menu {
                id: optionsMenu
                x: parent.width - width - 5
                y: parent.y + parent.height
                transformOrigin: Menu.TopRight

                DetailedMenuItem {
                    iconFile: "qrc:///img/database.svg"
                    text: "Edit Data"
                    description: "Edit the underlying data model sent to your QML files"
                    onTriggered: dataManager.requestEditData()
                }
                DetailedMenuItem {
                    iconFile: "qrc:///img/mobile.svg"
                    text: "Live preview"
                    description: "Try your project LIVE on devices from the same network"
                    onTriggered: serverDialog.open()
                }
                DetailedMenuItem {
                    iconFile: "qrc:///img/dolly-flatbed.svg"
                    text: "Publish project"
                    description: "Generates a Qt project and a runnable .exe file"
                    onTriggered: publishDialog.open()
                }
                DetailedMenuItem {
                    iconFile: "qrc:///img/help.svg"
                    text: "Help"
                    description: "View keyboard shortcuts reference"
                    onTriggered: helpDialog.open()
                }

                MenuSeparator {}

                MenuItem {
                    text: "About"
                    onTriggered: aboutDialog.open()
                }
            }
        } // End overflow Button
    } // End RowLayout

    // ----------------------------------------------------------------------------------------
    // Other views
    // ----------------------------------------------------------------------------------------

    Dialog {
        id: helpDialog
        modal: true
        focus: true
        title: "Help"
        x: (root.width - width) / 2
        y: root.height / 6
        width: Math.min(root.width, root.height) / 3 * 2
        contentHeight: shortcutsGrid.height


         GridLayout {
             id: shortcutsGrid

             width: helpDialog.availableWidth
             columns: 2

             Label { text: "Filter files" }
             Label { text: "" + shortcutFileFilter.sequence }

             Label { text: "Toggle folder panel" }
             Label { text: "" + shortcutFolderSelectorPane.sequence }

             Label { text: "Toggle quick editor" }
             Label { text: "" + quickEditorToggleShortcut.sequence }

             Label { text: "Toggle options pane" }
             Label { text: "" + shortcutOptionsPane.sequence }
         }

//        Label {
//            id: helpLabel
//            width: helpDialog.availableWidth
////            height: helpDialog.availableHeight

//            text: "Shortcuts\n"
//                  + "Filter files"         + ": %1 \n".arg(shortcutFileFilter.sequence)
//                  + "Toggle folder panel"  + ": %1 \n".arg(shortcutFolderSelectorPane.sequence)
//                  + "Toggle quick editor"  + ": %1 \n".arg(quickEditorToggleShortcut.sequence)
//                  + "Toggle options panel" + ": %1 \n".arg(shortcutOptionsPane.sequence)
//        }
    }

    Dialog {
        id: aboutDialog
        modal: true
        focus: true
        title: "About"
        x: (root.width - width) / 2
        y: root.height / 6
        width: Math.min(root.width, root.height) / 3 * 2
        contentHeight: aboutColumn.height

        Image {
            id: appIcon
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            height: aboutDialog.availableHeight * 0.9
            width: height

            source: "qrc:///img/appIcon.png"
            fillMode: Image.PreserveAspectFit
        }

        Column {
            id: aboutColumn
            spacing: 20
            width: aboutDialog.availableWidth - appIcon.width - 20
            anchors.left: appIcon.right
            anchors.leftMargin: 20

            Label {
                width: parent.width
                text: "QmlPlayground 0.9 Beta"
                wrapMode: Label.Wrap
                font.pixelSize: 14
            }
            ClickableLabel {
                width: parent.width
                wrapMode: Label.Wrap

                text: "Author: Vincent Ponchaut\n"
                font.pixelSize: 12

                onClicked: {
                    Qt.openUrlExternally("https://github.com/VincentPonchaut")
                }
            }

        }
    }

    Dialog {
        id: serverDialog
        modal: true
        focus: true
        title: "Live preview"
        x: (root.width - width) / 2
        y: root.height / 6
        width: 400
        contentHeight: serverDialogColumn.height

        Column {
            id: serverDialogColumn
            width: serverDialog.availableWidth
            spacing: 20

            TextField {
                id: serverNameTextField
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width * 0.88
                placeholderText: "Enter id..."

                readOnly: serverControl.available
                onTextChanged: {
                    serverControl.serverId = text
                }
                onAccepted: {
                    if (!serverControl.available)
                        serverControl.start()
                }

            }
            Label {
                width: parent.width * 0.88
                anchors.horizontalCenter: parent.horizontalCenter
                text: "The ID will be used to recognize this host on the local network"
                wrapMode: Label.Wrap
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Connected clients: %1".arg(serverControl.activeClients)
            }

            Button {
                width: parent.width * 0.88
                anchors.horizontalCenter: parent.horizontalCenter

                text: serverControl.available ? "Stop" : "Start"
                enabled: serverControl.available || serverNameTextField.text.length > 0

                onClicked: {
                    if (serverControl.available)
                        serverControl.stop()
                    else {
                        serverControl.start()
                    }
//                    serverDialog.close()
                }
            }

            Label {
                width: parent.width
                text: "The client is available for windows and android.\nYou can download it here."
                font.italic: true
                font.pointSize: 11
                color: "grey"
            }
        }
    }
}
